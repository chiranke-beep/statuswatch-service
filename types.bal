// Statuspage.io v2 API payload schema
public type StatusIndicator record {
    string indicator;
    string description;
};

public type StatusPagePayload record {
    StatusIndicator status;
};

public type ServiceStatus "OPERATIONAL"|"DEGRADED"|"OUTAGE"|"UNREACHABLE";

public type ServiceHealth record {
    string name;
    ServiceStatus status;
    string details;
    decimal responseTimeMs?;
};

public type SystemStatus "ALL_OPERATIONAL"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE";

public type SystemOverview record {
    SystemStatus overallStatus;
    int totalMonitored;
    int healthyCount;
    string timestamp;
    ServiceHealth[] services;
};