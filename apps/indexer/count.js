import fs from "fs";

// Read the log file
const logContent = fs.readFileSync("./logs.txt", "utf-8");

// Split the content into lines
const lines = logContent.split("\n");

// Initialize objects to store counts and signatures
const programIdCounts = {};
const parentProgramIdCounts = {};
const noParentProgramIdSignatures = [];

let isBufferTrue = false;
let currentSignature = "";

// Process each line
lines.forEach((line) => {
  if (line.trim().length === 88 && /^[A-Za-z0-9]+$/.test(line.trim())) {
    currentSignature = line.trim();
  } else if (line.trim() === "BUFFER: true") {
    isBufferTrue = true;
  } else if (isBufferTrue && line.startsWith("{")) {
    try {
      const data = JSON.parse(line);
      if (data.instructions && data.instructions.length > 0) {
        const instruction = data.instructions[0];

        // Count programId
        const programId = instruction.programId;
        programIdCounts[programId] = (programIdCounts[programId] || 0) + 1;

        // Check for parentProgramId
        if (instruction.parentProgramId) {
          const parentProgramId = instruction.parentProgramId;
          parentProgramIdCounts[parentProgramId] = (parentProgramIdCounts[parentProgramId] || 0) + 1;
        } else {
          noParentProgramIdSignatures.push(currentSignature);
        }
      }
    } catch (error) {
      console.error("Error parsing JSON:", error);
    }
    isBufferTrue = false;
  }
});

// Print results
console.log("Program IDs:");
Object.entries(programIdCounts).forEach(([id, count]) => {
  console.log(`${id}: ${count} times`);
});

console.log("\nParent Program IDs:");
Object.entries(parentProgramIdCounts).forEach(([id, count]) => {
  console.log(`${id}: ${count} times`);
});

console.log("\nNo Parent Program ID count:", noParentProgramIdSignatures.length);
console.log("Signatures for cases with no Parent Program ID:");
noParentProgramIdSignatures.forEach((signature) => {
  console.log(signature);
});
