#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

resource "azurerm_portal_dashboard" "pipeline_status_dashboard" {
  name                 = "PipelineStatusDashboard"
  location             = var.core_rg_location
  resource_group_name  = var.core_rg_name
  dashboard_properties = <<EOF
{
    "lenses": {
      "0": {
        "order": 0,
        "parts": {
          "0": {
            "position": {
              "x": 0,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "options",
                  "value": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "/subscriptions/d8ef0881-fb74-4e8b-9c71-fc24f5bd4ab2/resourceGroups/rg-tborflwhr-dev/providers/Microsoft.DataFactory/factories/adf-tborflwhr-dev"
                          },
                          "name": "PipelineSucceededRuns",
                          "aggregationType": 1,
                          "namespace": "microsoft.datafactory/factories",
                          "metricVisualization": {
                            "displayName": "Succeeded pipeline runs metrics",
                            "resourceDisplayName": "adf-tborflwhr-dev"
                          }
                        }
                      ],
                      "title": "Sum Succeeded pipeline runs metrics for adf-tborflwhr-dev",
                      "titleKind": 1,
                      "visualization": {
                        "chartType": 2,
                        "legendVisualization": {
                          "isVisible": true,
                          "position": 2,
                          "hideSubtitle": false
                        },
                        "axisVisualization": {
                          "x": {
                            "isVisible": true,
                            "axisType": 2
                          },
                          "y": {
                            "isVisible": true,
                            "axisType": 1
                          }
                        }
                      },
                      "timespan": {
                        "relative": {
                          "duration": 86400000
                        },
                        "showUTCTime": true,
                        "grain": 1
                      }
                    }
                  },
                  "isOptional": true
                },
                {
                  "name": "sharedTimeRange",
                  "isOptional": true
                }
              ],
              "type": "Extension/HubsExtension/PartType/MonitorChartPart",
              "settings": {
                "content": {
                  "options": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "/subscriptions/d8ef0881-fb74-4e8b-9c71-fc24f5bd4ab2/resourceGroups/rg-tborflwhr-dev/providers/Microsoft.DataFactory/factories/adf-tborflwhr-dev"
                          },
                          "name": "PipelineSucceededRuns",
                          "aggregationType": 1,
                          "namespace": "microsoft.datafactory/factories",
                          "metricVisualization": {
                            "displayName": "Succeeded pipeline runs metrics",
                            "resourceDisplayName": "adf-tborflwhr-dev"
                          }
                        }
                      ],
                      "title": "Sum Succeeded pipeline runs metrics for adf-tborflwhr-dev",
                      "titleKind": 1,
                      "visualization": {
                        "chartType": 2,
                        "legendVisualization": {
                          "isVisible": true,
                          "position": 2,
                          "hideSubtitle": false
                        },
                        "axisVisualization": {
                          "x": {
                            "isVisible": true,
                            "axisType": 2
                          },
                          "y": {
                            "isVisible": true,
                            "axisType": 1
                          }
                        },
                        "disablePinning": true
                      }
                    }
                  }
                }
              },
              "filters": {
                "MsPortalFx_TimeRange": {
                  "model": {
                    "format": "utc",
                    "granularity": "auto",
                    "relative": "1440m"
                  }
                }
              }
            }
          },
          "1": {
            "position": {
              "x": 6,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "options",
                  "isOptional": true
                },
                {
                  "name": "sharedTimeRange",
                  "isOptional": true
                }
              ],
              "type": "Extension/HubsExtension/PartType/MonitorChartPart",
              "settings": {
                "content": {
                  "options": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "/subscriptions/d8ef0881-fb74-4e8b-9c71-fc24f5bd4ab2/resourceGroups/rg-tborflwhr-dev/providers/Microsoft.DataFactory/factories/adf-tborflwhr-dev"
                          },
                          "name": "PipelineFailedRuns",
                          "aggregationType": 1,
                          "namespace": "microsoft.datafactory/factories",
                          "metricVisualization": {
                            "displayName": "Failed pipeline runs metrics",
                            "resourceDisplayName": "adf-tborflwhr-dev"
                          }
                        }
                      ],
                      "title": "Sum Failed pipeline runs metrics for adf-tborflwhr-dev",
                      "titleKind": 1,
                      "visualization": {
                        "chartType": 2,
                        "legendVisualization": {
                          "isVisible": true,
                          "position": 2,
                          "hideSubtitle": false
                        },
                        "axisVisualization": {
                          "x": {
                            "isVisible": true,
                            "axisType": 2
                          },
                          "y": {
                            "isVisible": true,
                            "axisType": 1
                          }
                        },
                        "disablePinning": true
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "metadata": {
      "model": {
        "timeRange": {
          "value": {
            "relative": {
              "duration": 24,
              "timeUnit": 1
            }
          },
          "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        },
        "filterLocale": {
          "value": "en-us"
        },
        "filters": {
          "value": {
            "MsPortalFx_TimeRange": {
              "model": {
                "format": "utc",
                "granularity": "auto",
                "relative": "24h"
              },
              "displayCache": {
                "name": "UTC Time",
                "value": "Past 24 hours"
              },
              "filteredPartIds": [
                "StartboardPart-MonitorChartPart-6625aee4-97c5-428c-8a66-cc394795118a",
                "StartboardPart-MonitorChartPart-6625aee4-97c5-428c-8a66-cc39479511c2"
              ]
            }
          }
        }
      }
    }
}
EOF
}
