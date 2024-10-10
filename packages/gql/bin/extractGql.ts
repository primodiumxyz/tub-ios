import * as fs from 'fs';
import * as path from 'path';

function extractGraphQLOperations(filePath: string): string[] {
  const content = fs.readFileSync(filePath, 'utf-8');
  const regex = /graphql\(`([\s\S]*?)`\)/g;
  const operations: string[] = [];
  let match;

  while ((match = regex.exec(content)) !== null) {
    const operation = match[1]?.trim() ?? 'query';
    const lines = operation.split('\n');
    const firstLine = lines[0];
    const restLines = lines.slice(1).map(line => line.replace(/^\s{2}/, '')); // Remove first two spaces
    operations.push([firstLine, ...restLines].join('\n'));
  }

  return operations;
}

function writeGraphQLFile(operations: string[], outputPath: string): void {
  const content = operations.join('\n\n');
  fs.writeFileSync(outputPath, content);
}

function processFile(inputPath: string, outputPath?: string): void {
  const operations = extractGraphQLOperations(inputPath);

  if (operations.length === 0) {
    console.log(`No GraphQL operations found in ${inputPath}`);
    return;
  }

  if (!outputPath) {
    const baseName = path.basename(inputPath, '.ts');
    outputPath = `${baseName}.graphql`;
  }

  // Make sure the output path is relative to the current working directory
  outputPath = path.resolve(process.cwd(), outputPath);

  // Ensure the output directory exists
  const outputDir = path.dirname(outputPath);
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  writeGraphQLFile(operations, outputPath);
  console.log(`GraphQL operations extracted to ${outputPath}`);
}

// Check if a file path is provided as a command-line argument
if (process.argv.length < 3) {
  console.error('Usage: node extract-graphql.js <input-file.ts> [output-file.graphql]');
  process.exit(1);
}

const inputPath = process.argv[2];
const outputPath = process.argv[3];

// Resolve the input path relative to the current working directory
const resolvedInputPath = path.resolve(process.cwd(), inputPath!);

if (!fs.existsSync(resolvedInputPath)) {
  console.error(`File not found: ${resolvedInputPath}`);
  process.exit(1);
}

if (!resolvedInputPath.endsWith('.ts')) {
  console.error('The input file must be a .ts file.');
  process.exit(1);
}

processFile(resolvedInputPath, outputPath);