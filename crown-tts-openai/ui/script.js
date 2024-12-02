let isVisible = false;
let config = {
    MaxInputLength: 200,
    InputPlaceholder: "Enter text for TTS...",
    ButtonText: "Send"
};
let currentRadioState = {
    channel: 0,
    onRadio: false
};

window.addEventListener('message', function(event) {
    if (event.data.type === "ui") {
        isVisible = event.data.status;
        if (event.data.config) {
            config = event.data.config;
            updateUIWithConfig();
        }
        if (event.data.radioData) {
            updateRadioState(event.data.radioData);
        }
        document.getElementById("container").style.display = isVisible ? "block" : "none";
        if (isVisible) {
            document.getElementById("textInput").focus();
        }
    } else if (event.data.type === "playAudio") {
        playAudioStream(event.data.audioData, event.data.volume);
    } else if (event.data.type === "drawSpeaking") {
        updateSpeakingIndicator(event.data);
    }
});

function updateRadioState(radioData) {
    currentRadioState = radioData;
    const radioStatus = document.getElementById('radioStatus');
    const radioButton = document.getElementById('radioButton');

    if (radioData.onRadio) {
        radioStatus.textContent = `On Radio Channel: ${radioData.channel}`;
        radioStatus.classList.add('active');
        radioButton.disabled = false;
    } else {
        radioStatus.textContent = 'Not on radio';
        radioStatus.classList.remove('active');
        radioButton.disabled = true;
    }
}

function updateUIWithConfig() {
    const textInput = document.getElementById("textInput");
    const sendButton = document.getElementById("sendButton");

    textInput.maxLength = config.MaxInputLength;
    textInput.placeholder = config.InputPlaceholder;
    sendButton.textContent = config.ButtonText;
}

function playAudioStream(audioData, volume) {
    const binary = new Uint8Array(audioData.match(/.{2}/g).map(byte => parseInt(byte, 16)));
    const blob = new Blob([binary], { type: 'audio/mp3' });
    const audioUrl = URL.createObjectURL(blob);

    const audio = new Audio();
    audio.src = audioUrl;
    audio.volume = Math.min(1.0, volume);

    audio.play().catch(console.error);

    audio.onended = function() {
        URL.revokeObjectURL(audioUrl);
        audio.remove();
    };
}

function submitText(useRadio) {
    const textInput = document.getElementById("textInput");
    const text = textInput.value.trim();

    if (text.length === 0) return;

    fetch(`https://${GetParentResourceName()}/submit`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            text: text,
            useRadio: useRadio
        })
    })
        .then(resp => resp.json())
        .catch(error => console.error('Error:', error));

    textInput.value = "";
}

function updateSpeakingIndicator(data) {
    const speakingText = document.getElementById('speaking-text');

    if (data.display) {
        speakingText.style.display = 'block';
        speakingText.textContent = data.text;
        speakingText.style.left = (data.x * window.innerWidth) + 'px';
        speakingText.style.top = (data.y * window.innerHeight) + 'px';
        speakingText.style.transform = 'translate(-50%, -50%)';

        if (data.isRadio) {
            speakingText.classList.add('radio');
        } else {
            speakingText.classList.remove('radio');
        }
    } else {
        speakingText.style.display = 'none';
    }
}

document.addEventListener('keydown', function(event) {
    if (!isVisible) return;

    if (event.key === "Escape") {
        fetch(`https://${GetParentResourceName()}/exit`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        })
            .then(resp => resp.json())
            .catch(error => console.error('Error:', error));
    } else if (event.key === "Enter") {
        // Default to normal chat on Enter
        submitText(false);
    }
});

document.addEventListener('mousedown', function(event) {
    if (!isVisible) return;

    const container = document.getElementById("container");
    if (container.contains(event.target)) {
        event.stopPropagation();
    }
});