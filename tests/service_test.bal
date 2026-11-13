import ballerina/http;
import ballerina/test;

final http:Client testClient = check new ("http://localhost:9090/health");

@test:Config {}
function testPingEndpoint() returns error? {
    json res = check testClient->get("/ping");
    test:assertEquals(check res.status, "ok");
}

@test:Config {}
function testOverviewEndpoint() returns error? {
    SystemOverview overview = check testClient->get("/overview");
    test:assertEquals(overview.totalMonitored, 3);
    test:assertEquals(overview.services.length(), 3);
}

@test:Config {}
function testIndicatorMapping() {
    test:assertEquals(mapIndicator("none"), "OPERATIONAL");
    test:assertEquals(mapIndicator("minor"), "DEGRADED");
    test:assertEquals(mapIndicator("major"), "OUTAGE");
    test:assertEquals(mapIndicator("critical"), "OUTAGE");
    test:assertEquals(mapIndicator("other"), "OPERATIONAL");
}
