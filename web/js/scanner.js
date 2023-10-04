var model = undefined;

tf.loadGraphModel("model/model.json").then(async function (loadedModel) {
    // const dummyInput = tf.ones(loadedModel.inputs[0].shape);
    // const warmupResult =
    //     loadedModel
    //         .executeAsync(dummyInput)
    //         .then(function (pred) {
    //             tf.dispose(warmupResult);
    //             tf.dispose(dummyInput);
    //             model = loadedModel;
    //             console.log('model loaded');
    //         });
    model = loadedModel;
    console.log('model loaded');
});

const model_dim = [640, 640];
const videoElement = document.getElementById("videoElement");
const canvas = document.createElement("canvas");
const context = canvas.getContext("2d");
var cameraReady = false;

function isModelReady() {
    if (!model || !cameraReady) {
        return false;
    }
    return true;
}

function initCamera() {
    navigator.mediaDevices.getUserMedia({
        video: {
            width: { max: model_dim[0] },
            height: { max: model_dim[1] },
            facingMode: 'environment'
        }, audio: false
    })
        .then(function (stream) {
            videoElement.srcObject = stream;
            cameraReady = true;
        })
        .catch(function (error) {
            console.error("Error accessing media devices.", error);
        });
}

function disposeScanner() {
    cameraReady = false;
    const stream = videoElement.srcObject;
    const tracks = stream.getTracks();

    tracks.forEach((track) => {
        track.stop();
    });

    videoElement.srcObject = null;
}

function getFrameData() {
    if (!isModelReady()) {
        return JSON.stringify({ "image": "", "height": -1, "width": -1 });
    }

    canvas.width = videoElement.videoWidth;
    canvas.height = videoElement.videoHeight;
    context.drawImage(videoElement, 0, 0, videoElement.videoWidth, videoElement.videoHeight);
    const imageData = canvas.toDataURL('image/jpeg').split(',')[1];

    return JSON.stringify({
        "image": imageData,
        "height": videoElement.videoHeight,
        "width": videoElement.videoWidth
    });
}

async function getPredictions() {
    if (!isModelReady()) {
        return JSON.stringify({ "result": [] });
    }

    return JSON.stringify({
        "result": await predictFrame(),
    });
}

function wrap_result(obj, x_scale, y_scale) {
    return {
        "className": obj[5],
        "score": obj[6],
        "xmin": obj[1] * x_scale,
        "ymin": obj[2] * y_scale,
        "width": (obj[3] - obj[1]) * x_scale,
        "height": (obj[4] - obj[2]) * y_scale,
    }
}

function resetPrediction() {
    videoElement.play();
}

async function predictFrame() {
    if (!isModelReady()) {
        return;
    }

    try {

        tf.engine().startScope();

        const x_scale = videoElement.videoWidth / model_dim[0];
        const y_scale = videoElement.videoHeight / model_dim[1];

        const input = tf.tidy(() => {
            const tfimg = tf.image
                .resizeBilinear(tf.browser.fromPixels(videoElement), model_dim)
                .div(255.0)
                .transpose([2, 0, 1])
                .expandDims(0);
            return tfimg
        });

        videoElement.pause();

        var predictions = await model.executeAsync(input);
        predictions = predictions.arraySync();

        // console.log(predictions);

        tf.engine().endScope();

        var _result = [];

        for (let i = 0; i < predictions.length; i++) {
            var obj = predictions[i];
            if (obj[6] > 0.3) {
                _result.push(wrap_result(obj, x_scale, y_scale));
            }
        }

        // console.log(_result)

        return _result;

    } catch (error) {
        // console.log(error);
        return [];
    }
}

