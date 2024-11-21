let isVisible = false;
let config = {
    MaxInputLength: 200,
    InputPlaceholder: "Enter text for TTS...",
    ButtonText: "Send"
};

function playAudioStream(audioData, volume) {
    const binary = new Uint8Array(audioData.match(/.{2}/g).map(byte => parseInt(byte, 16)));
    const blob = new Blob([binary], { type: 'audio/mp3' });
    const audioUrl = URL.createObjectURL(blob);


    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const mediaElement = new Audio(audioUrl);
    const source = audioContext.createMediaElementSource(mediaElement);
    const gainNode = audioContext.createGain();


    source.connect(gainNode);
    gainNode.connect(audioContext.destination);


    gainNode.gain.setValueAtTime(volume, audioContext.currentTime);


    mediaElement.play().catch(console.error);
    mediaElement.onended = function() {
        URL.revokeObjectURL(audioUrl);
        audioContext.close();
        mediaElement.remove();
    };
}

window.addEventListener('message', function(event) {
    if (event.data.type === "ui") {
        isVisible = event.data.status;
        if (event.data.config) {
            config = event.data.config;
            updateUIWithConfig();
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

function updateUIWithConfig() {
    const textInput = document.getElementById("textInput");
    const sendButton = document.getElementById("sendButton");

    textInput.maxLength = config.MaxInputLength;
    textInput.placeholder = config.InputPlaceholder;
    sendButton.textContent = config.ButtonText;
}

function submitText() {
    const textInput = document.getElementById("textInput");
    const text = textInput.value.trim();
    
    if (text.length === 0) return;

    fetch(`https://${GetParentResourceName()}/submit`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            text: text
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
        submitText();
    }
});

document.addEventListener('mousedown', function(event) {
    if (!isVisible) return;
    
    const container = document.getElementById("container");
    if (container.contains(event.target)) {
        event.stopPropagation();
    }
});