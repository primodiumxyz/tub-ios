import { start } from "@bin/tub-server"
import type { GlobalSetupContext } from 'vitest/node'
import { AddressInfo } from "ws"

let teardownHappened = false

declare module 'vitest' {
  export interface ProvidedContext {
    port: number
    host: string
  }
}

export default async function ({ provide }: GlobalSetupContext) {


  console.log("Setting up server for tests");
  const server = await start();

  const serverInfo = server.server.address();

  if (!serverInfo || typeof serverInfo !== 'object') {
    throw new Error('Server info not found')
  }

  provide('port', serverInfo.port)
  provide('host', serverInfo.address)

  return async () => {
    if (teardownHappened) {
      throw new Error('teardown called twice')
    }
    teardownHappened = true

    await server.close();
  }
}