import { Command } from "commander";
import chalk from "chalk";
import ora from "ora";
import { execSync, spawn } from "child_process";

interface OrgInfo {
  alias: string;
  username: string;
  instanceUrl: string;
  status: string;
  isDefaultDevHub?: boolean;
  isDefaultOrg?: boolean;
  expirationDate?: string;
}

async function listOrgs(options: { json?: boolean }): Promise<void> {
  const spinner = ora("Fetching connected orgs...").start();

  try {
    const output = execSync("sf org list --json", {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });

    const data = JSON.parse(output);
    spinner.stop();

    const scratchOrgs: OrgInfo[] = data.result?.scratchOrgs || [];
    const nonScratchOrgs: OrgInfo[] = data.result?.nonScratchOrgs || [];
    const allOrgs = [...nonScratchOrgs, ...scratchOrgs];

    if (options.json) {
      console.log(JSON.stringify(allOrgs, null, 2));
      return;
    }

    console.log();
    console.log(chalk.bold.cyan("Connected Salesforce Orgs"));
    console.log(chalk.gray("─".repeat(70)));

    if (allOrgs.length === 0) {
      console.log(chalk.yellow("  No orgs connected"));
      console.log(chalk.gray("  Run 'elaro org login' to connect to an org"));
    } else {
      console.log();
      console.log(
        chalk.gray(
          "  " +
            "ALIAS".padEnd(20) +
            "USERNAME".padEnd(35) +
            "STATUS".padEnd(15)
        )
      );
      console.log(chalk.gray("  " + "─".repeat(68)));

      for (const org of allOrgs) {
        const alias = (org.alias || "N/A").padEnd(20);
        const username = (org.username || "N/A").substring(0, 33).padEnd(35);
        const status = org.status || "Unknown";
        const statusColor =
          status === "Active" ? chalk.green : status === "Expired" ? chalk.red : chalk.yellow;

        let prefix = "  ";
        if (org.isDefaultOrg) {
          prefix = chalk.cyan("→ ");
        }

        console.log(`${prefix}${alias}${username}${statusColor(status)}`);
      }
    }

    console.log();
  } catch (error) {
    spinner.fail("Failed to list orgs");
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    console.log(
      chalk.gray("Make sure Salesforce CLI is installed: npm install -g @salesforce/cli")
    );
    process.exit(1);
  }
}

async function loginOrg(options: {
  alias?: string;
  instanceUrl?: string;
  devhub?: boolean;
}): Promise<void> {
  console.log();
  console.log(chalk.bold.cyan("Salesforce Org Login"));
  console.log(chalk.gray("─".repeat(50)));
  console.log();

  const aliasFlag = options.alias ? `--alias ${options.alias}` : "";
  const instanceFlag = options.instanceUrl
    ? `--instance-url ${options.instanceUrl}`
    : "";
  const devhubFlag = options.devhub ? "--set-default-dev-hub" : "--set-default";

  const command = `sf org login web ${aliasFlag} ${instanceFlag} ${devhubFlag}`;

  console.log(chalk.gray(`Running: ${command}`));
  console.log();
  console.log(chalk.yellow("A browser window will open for authentication..."));
  console.log();

  try {
    const child = spawn("sf", ["org", "login", "web", ...command.split(" ").slice(4)], {
      stdio: "inherit",
      shell: true,
    });

    child.on("close", (code) => {
      if (code === 0) {
        console.log();
        console.log(chalk.green("Successfully logged in!"));
      } else {
        console.log();
        console.log(chalk.red("Login failed"));
        process.exit(1);
      }
    });
  } catch (error) {
    console.error(chalk.red("Failed to initiate login"));
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    process.exit(1);
  }
}

async function openOrg(options: { targetOrg?: string }): Promise<void> {
  const spinner = ora("Opening Salesforce org...").start();

  try {
    const orgFlag = options.targetOrg ? `--target-org ${options.targetOrg}` : "";
    execSync(`sf org open ${orgFlag}`, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });

    spinner.succeed("Org opened in browser");
  } catch (error) {
    spinner.fail("Failed to open org");
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    process.exit(1);
  }
}

async function createScratchOrg(options: {
  alias?: string;
  duration?: number;
  json?: boolean;
}): Promise<void> {
  const spinner = ora("Creating scratch org...").start();

  try {
    const alias = options.alias || "elaro-dev";
    const duration = options.duration || 30;

    spinner.text = `Creating scratch org '${alias}' (${duration} days)...`;

    const command = `sf org create scratch -f config/elaro-scratch-def.json -a ${alias} -d ${duration} --json`;
    const output = execSync(command, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 300000, // 5 minutes
    });

    const data = JSON.parse(output);
    spinner.stop();

    if (options.json) {
      console.log(JSON.stringify(data.result, null, 2));
      return;
    }

    console.log();
    console.log(chalk.green.bold("Scratch org created successfully!"));
    console.log();
    console.log(chalk.bold("Org Details:"));
    console.log(`  Alias:        ${chalk.cyan(alias)}`);
    console.log(`  Username:     ${data.result?.username || "N/A"}`);
    console.log(`  Instance URL: ${data.result?.instanceUrl || "N/A"}`);
    console.log(`  Expires:      ${duration} days`);
    console.log();
    console.log(chalk.bold("Next steps:"));
    console.log(`  1. Deploy code:     ${chalk.gray("elaro deploy -o " + alias)}`);
    console.log(`  2. Assign permset:  ${chalk.gray(`sf org assign permset -n Elaro_Admin -o ${alias}`)}`);
    console.log(`  3. Open org:        ${chalk.gray("elaro org open -o " + alias)}`);
    console.log();
  } catch (error) {
    spinner.fail("Failed to create scratch org");
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    console.log();
    console.log(chalk.yellow("Troubleshooting:"));
    console.log("  - Ensure you're authenticated to a Dev Hub");
    console.log("  - Check config/elaro-scratch-def.json exists");
    console.log("  - Verify your Dev Hub has available scratch org allocations");
    process.exit(1);
  }
}

async function deleteOrg(options: {
  targetOrg: string;
  noPrompt?: boolean;
}): Promise<void> {
  if (!options.targetOrg) {
    console.error(chalk.red("Error: --target-org is required"));
    process.exit(1);
  }

  const spinner = ora(`Deleting org '${options.targetOrg}'...`).start();

  try {
    const promptFlag = options.noPrompt ? "--no-prompt" : "";
    execSync(`sf org delete scratch -o ${options.targetOrg} ${promptFlag}`, {
      encoding: "utf-8",
      stdio: options.noPrompt ? ["pipe", "pipe", "pipe"] : "inherit",
    });

    spinner.succeed(`Org '${options.targetOrg}' deleted`);
  } catch (error) {
    spinner.fail("Failed to delete org");
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    process.exit(1);
  }
}

export const orgCommand = new Command("org")
  .description("Manage Salesforce orgs")
  .addCommand(
    new Command("list")
      .description("List all connected Salesforce orgs")
      .option("--json", "Output in JSON format")
      .action(listOrgs)
  )
  .addCommand(
    new Command("login")
      .description("Login to a Salesforce org")
      .option("-a, --alias <alias>", "Alias for the org")
      .option("-i, --instance-url <url>", "Instance URL (for sandboxes)")
      .option("-d, --devhub", "Set as default Dev Hub")
      .action(loginOrg)
  )
  .addCommand(
    new Command("open")
      .description("Open Salesforce org in browser")
      .option("-o, --target-org <alias>", "Target org alias")
      .action(openOrg)
  )
  .addCommand(
    new Command("create")
      .description("Create a new scratch org")
      .option("-a, --alias <alias>", "Alias for the scratch org", "elaro-dev")
      .option("-d, --duration <days>", "Duration in days", "30")
      .option("--json", "Output in JSON format")
      .action(createScratchOrg)
  )
  .addCommand(
    new Command("delete")
      .description("Delete a scratch org")
      .requiredOption("-o, --target-org <alias>", "Target org alias to delete")
      .option("-p, --no-prompt", "Skip confirmation prompt")
      .action(deleteOrg)
  );
