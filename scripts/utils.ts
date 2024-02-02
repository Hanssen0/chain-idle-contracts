import { mkdir, readFile, writeFile } from "fs/promises";
import { network, upgrades } from "hardhat";
import path from "path";

const MIGRATION_DIR = "../migrations";

export interface ContractHistory {
  address: string;
  deployments: { implementation: string; date: string; owner: string }[];
}

export interface ContractMigration {
  owner: string;
  address: string;
}

export async function saveToFile(
  migration: ContractMigration,
  name: string,
  networkName?: string
) {
  const migrationPath = path.join(__dirname, MIGRATION_DIR);

  await mkdir(migrationPath, { recursive: true });

  const filePath = path.join(
    migrationPath,
    `${name}-${networkName ?? network.name}.json`
  );
  const existed: ContractHistory = await (async () => {
    try {
      return JSON.parse((await readFile(filePath)).toString());
    } catch (error) {
      return { address: migration.address, deployments: [] };
    }
  })();

  existed.deployments.push({
    implementation: await upgrades.erc1967.getImplementationAddress(
      migration.address
    ),
    date: new Date().toISOString(),
    ...migration,
  });
  await writeFile(filePath, JSON.stringify(existed, undefined, 2));
}

export async function getDeployed(
  name: string,
  networkName?: string
): Promise<string | undefined> {
  const filePath = path.join(
    __dirname,
    MIGRATION_DIR,
    `${name}-${networkName ?? network.name}.json`
  );

  try {
    const existed: ContractHistory = JSON.parse(
      (await readFile(filePath)).toString()
    );
    return existed.address;
  } catch (error) {
    return undefined;
  }
}
