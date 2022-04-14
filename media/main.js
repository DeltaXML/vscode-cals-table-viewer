// This script will be run within the webview itself
// It cannot access the main VS Code APIs directly.
const vscode = acquireVsCodeApi();
const init = () => {
    // Handle messages sent from the extension to the webview
    window.addEventListener('message', event => {
        const message = event.data; // The json data that the extension sent
        switch (message.command) {
            case 'update':
                // @ts-ignore
                update(SaxonJS, { sef: saxonData.sef, sourceText: message.sourceText, filename: message.filename });
                break;
        }
    });
};

const update = (
    /** @type {{ getProcessorInfo: () => { (): any; new (): any; productName: any; }; transform: (arg0: { stylesheetLocation: string; sourceText: string; logLevel: number; stylesheetParams: any }, arg1: string) => void; }} */
    saxonProcessor, 
    /** @type {{ sef: string; sourceText: string; filename: string }} */
    txData) => {
    console.log(saxonProcessor.getProcessorInfo().productName);
    try {
        saxonProcessor.transform({
            stylesheetLocation: txData.sef,
            sourceText: txData.sourceText,
            logLevel: 2,
            stylesheetParams: { "headerText": txData.filename }
        },
        "async");
    } catch (error) {
        vscode.postMessage({
            command: 'alert',
            // @ts-ignore
            text: JSON.stringify("Transform error: " + error.toString())
        });
    }
}
init();

