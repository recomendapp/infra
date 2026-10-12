import { readFile } from "node:fs/promises";
import { parse } from "yaml";
import { clusterConfigPath } from "./paths.js";

interface RawPool {
  name?: string;
  instance_count?: number;
  autoscaling?: { enabled?: boolean; min_instances?: number; max_instances?: number };
}

interface RawClusterConfig {
  cluster_name: string;
  k3s_version: string;
  masters_pool: { instance_type: string; instance_count: number; locations: string[] };
  worker_node_pools?: RawPool[];
}

export interface ClusterConfig {
  clusterName: string;
  k3sVersion: string;
  masterCount: number;
  /** Lower bound only — autoscaled pools sit anywhere between min and max. */
  minWorkerCount: number;
  maxWorkerCount: number;
}

/**
 * Most worker pools here are autoscaled and carry no instance_count, only
 * autoscaling.min_instances/max_instances. Summing instance_count alone would
 * read those as zero, so the node-ready step would wait for too few nodes and
 * pass before the cluster was actually up.
 */
function poolBounds(pool: RawPool): { min: number; max: number } {
  if (pool.autoscaling?.enabled) {
    return {
      min: pool.autoscaling.min_instances ?? 0,
      max: pool.autoscaling.max_instances ?? pool.autoscaling.min_instances ?? 0,
    };
  }
  const fixed = pool.instance_count ?? 0;
  return { min: fixed, max: fixed };
}

export async function loadClusterConfig(): Promise<ClusterConfig> {
  const raw = await readFile(clusterConfigPath, "utf8");
  const parsed = parse(raw) as RawClusterConfig;

  const bounds = (parsed.worker_node_pools ?? []).map(poolBounds);

  return {
    clusterName: parsed.cluster_name,
    k3sVersion: parsed.k3s_version,
    masterCount: parsed.masters_pool.instance_count,
    minWorkerCount: bounds.reduce((sum, b) => sum + b.min, 0),
    maxWorkerCount: bounds.reduce((sum, b) => sum + b.max, 0),
  };
}
