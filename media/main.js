// This script will be run within the webview itself
// It cannot access the main VS Code APIs directly.
const vscode = acquireVsCodeApi();
const init = () => {
    // Handle messages sent from the extension to the webview
    window.addEventListener('message', async event => {
        const message = event.data; // The json data that the extension sent
        switch (message.command) {
            case 'update':
                // @ts-ignore
                await update(SaxonJS, { sef: saxonData.sef, sourceText: message.sourceText, sourceFilename: message.sourceFilename, method: message.method });
                break;
        }
    });
};

const update = async (
    /** @type {{ getProcessorInfo: () => { (): any; new (): any; productName: any; }; transform: (arg0: { stylesheetLocation: string; initialTemplate: string; logLevel: number; stylesheetParams: any }, arg1: string) => Promise<any>; }} */
    saxonProcessor, 
    /** @type {{ sef: string; sourceText: string; sourceFilename: string; method: string }} */
    txData) => {
    try {
        await saxonProcessor.transform({
            stylesheetLocation: txData.sef,
            initialTemplate: "main",
            logLevel: 2,
            stylesheetParams: { "sourceFilename": txData.sourceFilename, "sourceText": txData.sourceText, "method": txData.method }
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

