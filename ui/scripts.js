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

                $.post('http://spray-can/spray', JSON.stringify({
                    image: "image1.png"})
            );
            } else {
                selectedButton = null;
            }
        });
    });
});

window.addEventListener('message', function(event) {
    let item = event.data;
    console.log(GetParentResourceName());
    if (item.showUI) {
        $('.container').show();
    } else {
        $('.container').hide();
    }
});

fetch(`https://${GetParentResourceName()}/spray`, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify({
        itemId: 'my-item'
    })
}).then(resp => resp.json()).then(resp => console.log(resp));