using 'DynamicElements'
# TODO: move code related to comments to separate class
class DynamicElements.Topic extends ShikiEditable
  I18N_KEY = 'frontend.dynamic_elements'

  _type: -> 'topic'
  _type_label: -> 'Топик'

  # similar to hash from JsExports::TopicsExport#serialzie
  _default_model: ->
    can_destroy: false
    can_edit: false
    id: parseInt(@root.id)
    is_viewed: true
    user_id: @$root.data('user_id')

  initialize: ->
    # data attribute is set in Topics.Tracker
    @model = @$root.data('model') || @_default_model()

    if SHIKI_USER.user_ignored(@model.user_id) || SHIKI_USER.topic_ignored(@model.id)
      if document.body.id == 'topics_show'
        @_toggle_ignored true
      else
        @$root.remove()
        return

    @$body = @$inner.children('.body')

    @$editor_container = @$('.editor-container')
    @$editor = @$('.b-shiki_editor')

    if USER_SIGNED_IN && DAY_REGISTERED && @$editor.length
      @editor = new ShikiEditor(@$editor)
    else
      @$editor.replaceWith(
        "<div class='b-nothing_here'>
          #{t 'frontend.shiki_editor.not_available'}
        </div>"
      )

    @$comments_loader = @$('.comments-loader')
    @$comments_hider = @$('.comments-hider')
    @$comments_collapser = @$('.comments-collapser')
    @$comments_expander = @$('.comments-expander')

    @is_preview = @$root.hasClass('b-topic-preview')
    @is_cosplay = @$root.hasClass('b-cosplay-topic')
    @is_review = @$root.hasClass('b-review-topic')

    @_activate_appear_marker() if @model && !@model.is_viewed
    @_activate_vote_button() if @model
    @$inner.one 'mouseover', @_deactivate_inaccessible_buttons
    $('.item-mobile', @$inner).one @_deactivate_inaccessible_buttons

    if @is_preview
      @$body.imagesLoaded @_check_height
      @_check_height()

    if @is_cosplay && !@is_preview
      @$('.b-cosplay_gallery .b-gallery').gallery()

    # ответ на топик
    $('.item-reply', @$inner).on 'click', =>
      reply = if @$root.data 'generated'
        ''
      else
        "[entry=#{@$root.attr('id')}]#{@$root.data 'user_nickname'}[/entry], "

      @$root.trigger 'comment:reply', [reply]

    @$editor
      .on 'ajax:success', (e, response) =>
        $new_comment = $(response.html).process(response.JS_EXPORTS)

        @$('.b-comments').find('.b-nothing_here').remove()
        if @$editor.is(':last-child')
          @$('.b-comments').append $new_comment
        else
          @$('.b-comments').prepend $new_comment

        $new_comment.yellowFade()

        @editor.cleanup()
        @_hide_editor()

    $('.item-ignore', @$inner)
      .on 'ajax:before', ->
        $(@).toggleClass 'selected'

      .on 'ajax:success', (e, result) =>
        if result.is_ignored
          SHIKI_USER.ignore_topic result.topic_id
        else
          SHIKI_USER.unignore_topic result.topic_id

        @_toggle_ignored result.is_ignored

    # голосование за/против рецензии
    @$('.footer-vote .vote').on 'ajax:before', ->
      $(@).addClass('selected')
      $(@).siblings('.vote').removeClass('selected')

    # прочтение комментриев
    @on 'appear', (e, $appeared, by_click) =>
      $filtered_appeared = $appeared.not ->
        $(@).data('disabled') || !(
          @classList.contains('b-appear_marker') &&
            @classList.contains('active')
        )

      if $filtered_appeared.exists()
        interval = if by_click then 1 else 1500
        $objects = $filtered_appeared.closest(".shiki-object")
        $markers = $objects.find('.b-new_marker.active')
        ids = $objects
          .map ->
            $object = $(@)
            item_type = $object.data('appear_type')
            "#{item_type}-#{@id}"
          .toArray()

        $.ajax
          url: $filtered_appeared.data('appear_url')
          type: 'POST'
          data:
            ids: ids.join ","

        $filtered_appeared.remove()

        if $markers.data('reappear')
          $markers.addClass 'off'
        else
          $markers.css.bind($markers).delay(interval, opacity: 0)
          $markers.hide.bind($markers).delay(interval + 500)
          $markers.removeClass.bind($markers).delay(interval + 500, 'active')

    # ответ на комментарий
    @on 'comment:reply', (e, text, is_offtopic) =>
      # @editor is empty for unauthorized user
      if @editor
        @_show_editor()
        @editor.reply_comment text, is_offtopic

    # клик скрытию редактора
    @$('.b-shiki_editor').on 'click', '.hide', @_hide_editor

    @$comments_loader
      # подготовка к подгрузке новых комментов
      .on 'ajax:before', =>
        new_url = @$comments_loader
          .data('href-template')
          .replace('SKIP', @$comments_loader.data('skip'))

        @$comments_loader.data(href: new_url)

    @$comments_loader
      # подгрузка новых комментов
      .on 'ajax:success', (e, data) =>
        $new_comments = $("<div class='comments-loaded'></div>")
          .html(data.content)
          .process(data.JS_EXPORTS)

        @_filter_present_entries($new_comments)

        $new_comments
          .insertAfter(@$comments_loader)
          .animated_expand()

        limit = @$comments_loader.data('limit')
        count = @$comments_loader.data('count') - limit

        if count > 0
          @$comments_loader.data
            skip: @$comments_loader.data('skip') + limit
            count: count

          comment_count = Math.min(limit, count)
          comment_word =
            if @$comments_loader.data('only-summaries-shown')
              p(
                comment_count,
                t("#{I18N_KEY}.summary.one"),
                t("#{I18N_KEY}.summary.few"),
                t("#{I18N_KEY}.summary.many")
              )
            else
              p(
                comment_count,
                t("#{I18N_KEY}.comment.one"),
                t("#{I18N_KEY}.comment.few"),
                t("#{I18N_KEY}.comment.many")
              )
          of_total_comments =
            if count > limit
              "#{t("#{I18N_KEY}.of")} #{count}"
            else
              ''

          load_comments = t(
            "#{I18N_KEY}.load_comments"
            comment_count: comment_count,
            of_total_comments: of_total_comments,
            comment_word: comment_word
          )

          @$comments_loader.html(load_comments)
          @$comments_collapser.show()
        else
          @$comments_loader.remove()
          @$comments_loader = null
          @$comments_hider.show()
          @$comments_collapser.remove()

      # отображение комментариев
      .on 'click', (e) =>
        unless @$comments_loader.is('.click-loader')
          @$comments_loader.hide()
          @$('.comments-loaded').animated_expand()
          @$comments_hider.show()

    # скрытие комментариев
    @$comments_hider.on 'click', =>
      @$comments_hider.hide()
      @$('.comments-loaded').animated_collapse()
      @$comments_expander.show()

    # сворачивание комментариев
    @$comments_collapser.on 'click', =>
      @$comments_collapser.hide()
      @$comments_loader.hide()
      @$comments_expander.show()
      @$('.comments-loaded').animated_collapse()

    # разворачивание комментариев
    @$comments_expander.on 'click', (e) =>
      @$comments_expander.hide()
      @$('.comments-loaded').animated_expand()

      if @$comments_loader
        @$comments_loader.show()
        @$comments_collapser.show()
      else
        @$comments_hider.show()

    # realtime обновления
    # изменение / удаление комментария
    @on 'faye:comment:updated faye:message:updated faye:comment:deleted faye:message:deleted faye:comment:set_replies', (e, data) =>
      e.stopImmediatePropagation()
      trackable_type = e.type.match(/comment|message/)[0]
      trackable_id = data["#{trackable_type}_id"]

      if e.target == @$root[0]
        @$(".b-#{trackable_type}##{trackable_id}").trigger e.type, data

    # добавление комментария
    @on 'faye:comment:created faye:message:created', (e, data) =>
      e.stopImmediatePropagation()
      trackable_type = e.type.match(/comment|message/)[0]
      trackable_id = data["#{trackable_type}_id"]

      return if @$(".b-#{trackable_type}##{trackable_id}").exists()
      $placeholder = @_faye_placeholder(trackable_id, trackable_type)

      # уведомление о добавленном элементе через faye
      $(document.body).trigger 'faye:added'
      if OPTIONS.comments_auto_loaded
        $placeholder.click() if $placeholder.is(':appeared') && !$('textarea:focus').val()

    # изменение метки комментария
    @on 'faye:comment:marked', (e, data) =>
      e.stopImmediatePropagation()
      $(".b-comment##{data.comment_id}").view().mark(data.mark_kind, data.mark_value)

  # переключение топика в режим игнора/не_игнора
  _toggle_ignored: (is_ignored) ->
    $('.item-ignore', @$inner)
      .toggleClass('selected', is_ignored)
      .data(method: if is_ignored then 'DELETE' else 'POST')
    @$('.b-anime_status_tag.ignored').toggleClass 'hidden', !is_ignored

  # удаляем уже имеющиеся подгруженные элементы
  _filter_present_entries: ($comments) ->
    filter = 'b-comment'
    present_ids = $(".#{filter}", @$root).toArray().map (v) -> v.id

    exclude_selector = present_ids.map (id) ->
        ".#{filter}##{id}"
      .join(',')

    $comments.children().filter(exclude_selector).remove()

  # отображение редактора, если это превью топика
  _show_editor: ->
    if @is_preview && !@$editor_container.is(':visible')
      @$editor_container.show()#animated_expand()

  # скрытие редактора, если это превью топика
  _hide_editor: =>
    if @is_preview
      @$editor_container.hide()#animated_collapse()

  # получение плейсхолдера для подгрузки новых комментариев
  _faye_placeholder: (trackable_id, trackable_type) ->
    $placeholder = @$('.b-comments .faye-loader')

    unless $placeholder.exists()
      $placeholder = $('<div class="click-loader faye-loader"></div>')
        .appendTo(@$('.b-comments'))
        .data(ids: [])
        .on 'ajax:success', (e, data) ->
          $html = $(data.content).process data.JS_EXPORTS
          $placeholder.replaceWith $html

          $html.process()

    if $placeholder.data('ids').indexOf(trackable_id) == -1
      $placeholder.data
        ids: $placeholder.data('ids').include(trackable_id)
      $placeholder.data
        href: "/#{trackable_type}s/chosen/#{$placeholder.data("ids").join ","}"

      num = $placeholder.data('ids').length

      $placeholder.html if trackable_type == 'message'
        p(
          num,
          t("#{I18N_KEY}.new_message_added.one", count: num),
          t("#{I18N_KEY}.new_message_added.few", count: num),
          t("#{I18N_KEY}.new_message_added.many", count: num)
        )
      else
        p(
          num,
          t("#{I18N_KEY}.new_comment_added.one", count: num),
          t("#{I18N_KEY}.new_comment_added.few", count: num),
          t("#{I18N_KEY}.new_comment_added.many", count: num)
        )

    $placeholder

  # проверка высоты топика. урезание,
  # если текст слишком длинный (точно такой же код в shiki_comment)
  _check_height: =>
    if @is_review
      image_height = @$('.review-entry_cover img').height()
      read_more_height = 13 + 5 # 5px - read_more offset

      if image_height > 0
        @$('.body-truncated-inner').check_height
          max_height: image_height - read_more_height
          collapsed_height: image_height - read_more_height
          expand_html: ''

    else
      @$('.body-inner').check_height
        max_height: @MAX_PREVIEW_HEIGHT
        collapsed_height: @COLLAPSED_HEIGHT

  _reload_url: =>
    "/#{@_type()}s/#{@$root.attr 'id'}/reload?is_preview=#{@is_preview}"

  _activate_vote_button: ->
    if @model.voted_yes
      @$inner.find('.vote.yes').addClass 'selected'
    else if @model.voted_no
      @$inner.find('.vote.no').addClass 'selected'

  # скрытие действий, на которые у пользователя нет прав
  _deactivate_inaccessible_buttons: =>
    @$inner.find('.item-edit').addClass 'hidden' unless @model.can_edit
    @$inner.find('.item-delete').addClass 'hidden' unless @model.can_destroy
