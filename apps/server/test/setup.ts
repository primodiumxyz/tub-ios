import { start, server } from "@bin/tub-server"

let teardownHappened = false

export default async function () {
  console.log("Setting up server for tests");
  await start();

  return async () => {
    if (teardownHappened) {
      throw new Error('teardown called twice')
    }
    teardownHappened = true

    await server.close();
  }
}