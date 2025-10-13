import { OldListData, ListData, OldChecklistData } from '../types/ListParams';

/**
 * Method that checks if passed data is related to the legacy format and normalizes it
 * @param data - data to be checked
 * @returns - normalized data, ready to be used by Editorjs List tool
 */
export default function normalizeData(data: ListData | OldListData | OldChecklistData): ListData;
