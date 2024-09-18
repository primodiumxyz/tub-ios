import { Hex } from "viem";

export class TubService {
  // private tubPrivateKey: Hex;
  private running: boolean = false;
  private unsubscribe: (() => void) | null = null;

  // constructor(tubPrivateKey: Hex) {
  //   this.tubPrivateKey = tubPrivateKey;
  // }

  getStatus(): { status: number } {
    return { status: 200 };
  }

}
