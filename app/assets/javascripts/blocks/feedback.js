import ShikiModal from 'views/application/shiki_modal';
import flash from 'services/flash';

$(document).on('turbolinks:load', () => {
  const $feedback = $('.b-feedback');

  $('.marker-positioner', $feedback).on('ajax:success', (e, data) => {
    const $form = $(data);
    $form.find('.b-shiki_editor.unprocessed').shikiEditor();
    const modal = new ShikiModal($form);

    $form
      .one('mouseover', () => {
        const $antispam = $form.find('input[data-antispam]');

        if ($antispam.length) {
          $antispam.val($antispam.data('token').replace('antispam-', ''));
        }
      }).on('ajax:success', () => {
        flash.notice(I18n.t('frontend.blocks.feedback.message_sent'));
        modal.close();
      });
  });
});
