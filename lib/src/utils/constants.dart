///Key for logger injected [Request.context]
const String ctxLoggerKey = '__aw_router_logger';

// Zone-scoped tracking for the latest AwRequest instance
// Used to ensure Router.onError receives the freshest request.
final Object zoneCurrentRequestRefKey = Object();

class CurrentRequestRef {
  dynamic current;
  CurrentRequestRef(this.current);
}
