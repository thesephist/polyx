/* ligature ui interactions */

const $ = document.querySelector.bind(document);
const $$ = document.querySelectorAll.bind(document);

let noteChanged = false;
const noteEditor = $('.noteEditor textarea');
if (noteEditor) {
    window.addEventListener('beforeunload', evt => {
        if (noteChanged) {
            evt.preventDefault();
            evt.returnValue = '';
        }
    });
    // save button should not prevent leaving the page
    $('.saveButton').addEventListener('click', () => noteChanged = false);

    noteEditor.addEventListener('keydown', evt => {
        noteChanged = true;
        if (evt.key === 'Tab') {
            evt.preventDefault();
            const idx = evt.target.selectionStart;
            if (idx !== null) {
                const inputValue = evt.target.value;
                const front = inputValue.substr(0, idx);
                const back = inputValue.substr(idx);
                evt.target.value = front + '    ' + back;
                //> Rendering the new input value will
                //  make us lose focus on the textarea, so we put the
                //  focus back by selecting the area the user was just editing.
                evt.target.setSelectionRange(idx + 4, idx + 4);
            }
        }

        if (evt.key === 'Enter' && (evt.metaKey || evt.ctrlKey)) {
            // form submit shouldn't prevent leaving page
            noteChanged = false;
            $('form').submit();
        }
    })

}

function getDistance(date) {
    const delta = (Date.now() - date) / 1000; // seconds, not ms
    if (delta < 60) {
        return 'just now';
    } else if (delta < 3600) {
        return `${~~(delta / 60)}m`;
    } else if (delta < 86400) {
        return `${~~(delta / 3600)}h`
    } else if (delta < 86400 * 7) {
        return `${~~(delta / 86400)}d`
    } else if (delta < 86400 * 30) {
        return `${~~(delta / 86400 * 7)}m`
    } else {
        return `${~~(delta / 86400 * 365)}y`
    }
}

const noteCards = $$('li .noteCard');
Array.from(noteCards).forEach(card => {
    const mod = card.getAttribute('data-mod');
    if (mod) {
        const modDate = new Date((+mod) * 1000);
        card.querySelector('.modDate').textContent = getDistance(modDate);
    }
})
