import 'webgl_service.dart';
import 'webgl_service_stub.dart';

/// Creates the stub implementation for non-web platforms
WebGLService createWebGLService() {
  return WebGLServiceStub();
}