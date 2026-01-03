import 'webgl_service.dart';
import 'webgl_service_web_simple.dart';

/// Creates the web implementation for web platforms
WebGLService createWebGLService() {
  return WebGLServiceWebSimple();
}