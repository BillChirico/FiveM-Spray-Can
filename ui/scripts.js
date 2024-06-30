document.addEventListener('DOMContentLoaded', () => {
    const selectButtons = document.querySelectorAll('.select-button');
    let selectedButton = null;

    /**
     * Handles the click event on the select buttons, allowing the user to select a button and send a message to the parent resource indicating the selected spray.
     *
     * When a select button is clicked, the following occurs:
     * - If a button was previously selected, its text is reset to 'Select'
     * - If the clicked button is different from the previously selected button:
     *   - The clicked button's text is set to 'Selected'
     *   - The clicked button is stored as the new selected button
     *   - A message is sent to the parent resource with the selected spray
     *   - The selected button's text is reset to 'Select'
     * - If the clicked button is the same as the previously selected button, the selected button is set to null
     */
    selectButtons.forEach((button) => {
        button.addEventListener('click', () => {
            if (selectedButton) {
                selectedButton.textContent = 'Select';
            }
            if (selectedButton !== button) {
                button.textContent = 'Selected';
                selectedButton = button;

                $.post(
                    `https://${GetParentResourceName()}/spray-selected`,
                    JSON.stringify({
                        spray: selectedButton.id.toString(),
                    })
                );

                // Reset the selected buttons text
                selectedButton.textContent = 'Select';
            } else {
                selectedButton = null;
            }
        });
    });

    /**
     * Handles the click event on the close button, sending a post message to the parent resource to indicate the UI should be closed.
     */
    $('.close-button').click(function () {
        $.post(`https://${GetParentResourceName()}/close`);
    });
});

/**
 * Listens for messages from the parent window and shows or hides the UI container based on the message content.
 *
 * @param {MessageEvent} event - The message event received from the parent window.
 * @param {Object} event.data - The data payload of the message event.
 * @param {boolean} event.data.showUI - Indicates whether the UI container should be shown or hidden.
 */
window.addEventListener('message', function (event) {
    let item = event.data;

    if (item.showUI) {
        $('.container').show();
    } else {
        $('.container').hide();
    }
});
