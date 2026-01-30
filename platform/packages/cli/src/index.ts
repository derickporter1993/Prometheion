#!/usr/bin/env node

import { Command } from "commander";
import chalk from "chalk";
import { statusCommand } from "./commands/status.js";
import { scanCommand } from "./commands/scan.js";
import { deployCommand } from "./commands/deploy.js";
import { testCommand } from "./commands/test.js";
import { orgCommand } from "./commands/org.js";
import { configCommand } from "./commands/config.js";

const VERSION = "0.1.0";

const program = new Command();

program
  .name("elaro")
  .description(
    chalk.bold("Elaro CLI") +
      " - AI Compliance Brain for Salesforce\n\n" +
      "  Court-defensible compliance and AI governance platform for regulated organizations.\n" +
      "  Monitors configuration drift, permission sprawl, and compliance violations."
  )
  .version(VERSION, "-v, --version", "Display CLI version")
  .option("-o, --target-org <alias>", "Target Salesforce org alias")
  .option("--json", "Output results in JSON format")
  .option("--debug", "Enable debug output");

// Register commands
program.addCommand(statusCommand);
program.addCommand(scanCommand);
program.addCommand(deployCommand);
program.addCommand(testCommand);
program.addCommand(orgCommand);
program.addCommand(configCommand);

// Add helpful examples
program.addHelpText(
  "after",
  `
${chalk.bold("Examples:")}
  $ elaro status                    Check project and org status
  $ elaro scan --framework hipaa    Run HIPAA compliance scan
  $ elaro deploy --validate         Validate deployment (dry-run)
  $ elaro test --apex               Run Apex tests
  $ elaro org list                  List connected orgs

${chalk.bold("Documentation:")}
  https://github.com/derickporter1993/Elaro

${chalk.bold("Support:")}
  For issues, visit: https://github.com/derickporter1993/Elaro/issues
`
);

// Parse and execute
program.parse();
