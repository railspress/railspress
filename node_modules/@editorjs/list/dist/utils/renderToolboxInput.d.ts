/**
 * Options used in input rendering
 */
interface InputOptions {
    /**
     * Placeholder, that will be displayed in input
     */
    placeholder: string;
    /**
     * Input will be rendered with this value inside
     */
    value?: string;
    /**
     * Html attributes, that would be added to the input element
     */
    attributes?: {
        [key: string]: string;
    };
    /**
     * Flag that represents special behavior that prevents you from entering anything other than numbers
     */
    sanitize?: (value: string) => string;
}
/**
 * Method that renders html element for popover start with item
 * @param inputCallback - callback method that could change list attributes on input
 * @param inputOptions - options used in input rendering
 * @param inputOptions.value - input will be rendered with this value inside
 * @param inputOptions.placeholder - placeholder, that will be displayed in input
 * @param inputOptions.attributes - html attributes, that would be added to the input element
 * @returns - rendered html element
 */
export declare function renderToolboxInput(inputCallback: (index: string) => void, { value, placeholder, attributes, sanitize }: InputOptions): HTMLElement;
export {};
