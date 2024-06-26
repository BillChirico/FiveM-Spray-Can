document.addEventListener('DOMContentLoaded', () => {
    const selectButtons = document.querySelectorAll('.select-button');
    let selectedButton = null;

    selectButtons.forEach(button => {
        button.addEventListener('click', () => {
            if (selectedButton) {
                selectedButton.textContent = 'Select';
            }
            if (selectedButton !== button) {
                button.textContent = 'Selected';
                selectedButton = button;
                console.log(selectedButton);
                $.post(`https://${GetParentResourceName()}/spray-selected`, JSON.stringify({
                    image: "image1.png"})
            );
            } else {
                selectedButton = null;
            }
        });
    });

    $('.close-button').click(function() {
        $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({
            image: "image1.png"})
    });
});

window.addEventListener('message', function(event) {
    let item = event.data;

    if (item.showUI) {
        $('.container').show();
    } else {
        $('.container').hide();
    }
});

// fetch(`https://${GetParentResourceName()}/spray-selected`, {
//     method: 'POST',
//     headers: {
//         'Content-Type': 'application/json; charset=UTF-8',
//     },
//     body: JSON.stringify({
//         itemId: 'my-item'
//     })
// }).then(resp => resp.json()).then(resp => console.log(resp));