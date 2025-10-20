// Import all the channels to be used by Action Cable
// Realtime analytics channel is loaded conditionally on the realtime page
import { createConsumer } from "@rails/actioncable"

export const consumer = createConsumer()