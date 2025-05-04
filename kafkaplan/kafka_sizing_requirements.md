
| Category               | Parameter                            | Example / Recommendation                           |
|------------------------|--------------------------------------|----------------------------------------------------|
| **Workload**           | Estimated message size               | 1 KB                                               |
|                        | Messages per second                  | 10,000                                             |
|                        | Number of producers                  | 10                                                 |
|                        | Number of consumers                  | 20                                                 |
|                        | Number of topics                     | 5                                                  |
|                        | Partitions per topic                 | 20                                                 |
| **Throughput & Storage** | Write throughput (MB/s)              | `=bytes * msgs/sec / 1_048_576`                    |
|                        | Storage (TB)                         | `=bytes * msgs/sec * 86400 * days * RF / 1_099_511_627_776` |
| **Replication**        | Replication factor                   | 3                                                  |
|                        | Min in-sync replicas                 | 2                                                  |
| **Broker Specs**       | Broker count                         | 3–5                                                |
|                        | Instance type                        | `m5.4xlarge`                                       |
|                        | CPU cores                            | 16–32                                              |
|                        | RAM per broker                       | 64–128 GB                                          |
|                        | Disk type                            | NVMe SSD                                           |
|                        | Disk size                            | 1–2 TB                                             |
|                        | Network                              | ≥10 Gbps                                           |
| **Retention**          | Retention period                     | 7 days                                             |
|                        | Log segment size                     | 1 GB                                               |
|                        | Compaction                           | Yes / No                                           |
| **Config**             | Default partitions                   | 6 or more                                          |
|                        | Default replication factor           | 3                                                  |
|                        | JVM heap size                        | 6–16 GB                                            |
|                        | ZooKeeper nodes                      | 3 or 5                                             |
| **Scaling & Monitoring** | Metrics system                     | Prometheus / Control Center                        |
|                        | Auto-scaling                         | Cruise Control / manual                           |
|                        | Capacity buffer                      | 2–3x peak load                                     |
