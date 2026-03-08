package com.rohan.cicd;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public final class App {
  private App() {
  }

  public static void main(String[] args) throws IOException {
    HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
    server.createContext("/", new RootHandler());
    server.setExecutor(null);
    server.start();
    System.out.println("Server started on http://0.0.0.0:8080");
  }

  static String buildMessage() {
    return "CI/CD assignment app is running";
  }

  private static final class RootHandler implements HttpHandler {
    @Override
    public void handle(HttpExchange exchange) throws IOException {
      String response = buildMessage();
      byte[] payload = response.getBytes(StandardCharsets.UTF_8);
      exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
      exchange.sendResponseHeaders(200, payload.length);
      try (OutputStream outputStream = exchange.getResponseBody()) {
        outputStream.write(payload);
      }
    }
  }
}
