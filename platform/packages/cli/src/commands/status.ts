import { Command } from "commander";
import chalk from "chalk";
import ora from "ora";
import { execSync } from "child_process";

interface StatusOptions {
  targetOrg?: string;
  json?: boolean;
}

interface OrgStatus {
  connected: boolean;
  alias?: string;
  username?: string;
  instanceUrl?: string;
  apiVersion?: string;
}

interface ProjectStatus {
  version: string;
  apexClasses: number;
  lwcComponents: number;
  customObjects: number;
  testCoverage?: number;
}

async function getOrgStatus(targetOrg?: string): Promise<OrgStatus> {
  try {
    const orgFlag = targetOrg ? `--target-org ${targetOrg}` : "";
    const result = execSync(`sf org display ${orgFlag} --json`, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    const data = JSON.parse(result);
    return {
      connected: true,
      alias: data.result?.alias,
      username: data.result?.username,
      instanceUrl: data.result?.instanceUrl,
      apiVersion: data.result?.apiVersion,
    };
  } catch {
    return { connected: false };
  }
}

async function getProjectStatus(): Promise<ProjectStatus> {
  try {
    const apexClasses = execSync(
      'find force-app -name "*.cls" 2>/dev/null | wc -l',
      { encoding: "utf-8" }
    ).trim();
    const lwcComponents = execSync(
      'find force-app -type d -name "lwc" -exec find {} -mindepth 1 -maxdepth 1 -type d \\; 2>/dev/null | wc -l',
      { encoding: "utf-8" }
    ).trim();
    const customObjects = execSync(
      'find force-app -name "*.object-meta.xml" 2>/dev/null | wc -l',
      { encoding: "utf-8" }
    ).trim();

    return {
      version: "3.0.0",
      apexClasses: parseInt(apexClasses, 10) || 0,
      lwcComponents: parseInt(lwcComponents, 10) || 0,
      customObjects: parseInt(customObjects, 10) || 0,
    };
  } catch {
    return {
      version: "3.0.0",
      apexClasses: 0,
      lwcComponents: 0,
      customObjects: 0,
    };
  }
}

async function runStatus(options: StatusOptions): Promise<void> {
  const spinner = ora("Checking Elaro status...").start();

  try {
    const [orgStatus, projectStatus] = await Promise.all([
      getOrgStatus(options.targetOrg),
      getProjectStatus(),
    ]);

    spinner.stop();

    if (options.json) {
      console.log(JSON.stringify({ org: orgStatus, project: projectStatus }, null, 2));
      return;
    }

    console.log();
    console.log(chalk.bold.cyan("Elaro Status"));
    console.log(chalk.gray("─".repeat(50)));
    console.log();

    // Project Status
    console.log(chalk.bold("Project:"));
    console.log(`  Version:         ${chalk.green("v" + projectStatus.version)}`);
    console.log(`  Apex Classes:    ${chalk.yellow(projectStatus.apexClasses.toString())}`);
    console.log(`  LWC Components:  ${chalk.yellow(projectStatus.lwcComponents.toString())}`);
    console.log(`  Custom Objects:  ${chalk.yellow(projectStatus.customObjects.toString())}`);
    console.log();

    // Org Status
    console.log(chalk.bold("Salesforce Org:"));
    if (orgStatus.connected) {
      console.log(`  Status:          ${chalk.green("Connected")}`);
      console.log(`  Alias:           ${chalk.cyan(orgStatus.alias || "N/A")}`);
      console.log(`  Username:        ${orgStatus.username || "N/A"}`);
      console.log(`  Instance URL:    ${orgStatus.instanceUrl || "N/A"}`);
      console.log(`  API Version:     ${orgStatus.apiVersion || "N/A"}`);
    } else {
      console.log(`  Status:          ${chalk.red("Not Connected")}`);
      console.log(
        chalk.gray("  Run 'elaro org login' to connect to a Salesforce org")
      );
    }
    console.log();

    // Quick Actions
    console.log(chalk.bold("Quick Actions:"));
    console.log(`  ${chalk.gray("elaro scan")}        Run compliance scan`);
    console.log(`  ${chalk.gray("elaro test")}        Run tests`);
    console.log(`  ${chalk.gray("elaro deploy")}      Deploy to org`);
    console.log();
  } catch (error) {
    spinner.fail("Failed to get status");
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    process.exit(1);
  }
}

export const statusCommand = new Command("status")
  .description("Check Elaro project and org status")
  .option("-o, --target-org <alias>", "Target Salesforce org alias")
  .option("--json", "Output results in JSON format")
  .action(runStatus);
