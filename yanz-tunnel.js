import { connect } from "cloudflare:sockets";

var listProxy = [
  // VLESS 
  { path: "/vless1", protocol: "vless", proxy: "178.128.80.43:443", uuid: "pejabat-kurang-angaran-indonesia-cemas" },
  { path: "/vless2", protocol: "vless", proxy: "138.2.74.219:28616", uuid: "pejabat-kurang-angaran-indonesia-cemas" },
  { path: "/vless3", protocol: "vless", proxy: "194.127.193.124:24467", uuid: "pejabat-kurang-angaran-indonesia-cemas" },
  // VMess 
  { path: "/vmess1", protocol: "vmess", proxy: "178.128.80.43:443", uuid: "pejabat-kurang-angaran-indonesia-cemas", alterId: 0 },
  { path: "/vmess2", protocol: "vmess", proxy: "194.127.193.124:24467", uuid: "pejabat-kurang-angaran-indonesia-cemas", alterId: 0 },
  // Trojan 
  { path: "/trojan1", protocol: "trojan", proxy: "178.128.80.43:443", uuid: "pejabat-kurang-angaran-indonesia-cemas" },
  { path: "/trojan2", protocol: "trojan", proxy: "138.2.74.219:28616", uuid: "pejabat-kurang-angaran-indonesia-cemas" },
];

const DECOY_WEBSITE_URL = "https://google.com"; 

var proxyIP;
var proxyPort;

var worker_default = {
  async fetch(request, ctx) {
    try {
      const url = new URL(request.url);
      const upgradeHeader = request.headers.get("Upgrade");

      if (upgradeHeader === "websocket") {
        const entry = listProxy.find(e => url.pathname === e.path);
        if (entry) {
          [proxyIP, proxyPort] = entry.proxy.split(':'); 

          switch (entry.protocol) {
            case "vless":
              return await vlessOverWSHandler(request, entry);
            case "vmess":
              return await vmessOverWSHandler(request, entry);
            case "trojan":
              return await trojanOverWSHandler(request, entry);
            default:
              return new Response("Unsupported protocol for this path", { status: 400 });
          }
        }
      }

      if (url.pathname === '/api/configs-json') {
        const jsonData = await getConfigsJson(request.headers.get("Host"));
        return new Response(JSON.stringify(jsonData, null, 2), {
          status: 200,
          headers: { "Content-Type": "application/json;charset=utf-8" }
        });
      }

      if (url.pathname === '/api/urls-txt') {
        const txtData = await getUrlsTxt(request.headers.get("Host"));
        return new Response(txtData, {
          status: 200,
          headers: { "Content-Type": "text/plain;charset=utf-8" }
        });
      }

      const decoyRequest = new Request(DECOY_WEBSITE_URL, {
        headers: request.headers,
        method: request.method,
        body: request.body,
        redirect: 'follow'
      });

      const decoyResponse = await fetch(decoyRequest);
      const newResponse = new Response(decoyResponse.body, decoyResponse);
      newResponse.headers.delete('x-powered-by');
      newResponse.headers.delete('server');
      return newResponse;

    } catch (err) {
      console.error("Worker error:", err);
      try {
          const fallbackDecoyResponse = await fetch(DECOY_WEBSITE_URL);
          return new Response(fallbackDecoyResponse.body, fallbackDecoyResponse);
      } catch (fallbackErr) {
          return new Response("Error loading content: " + fallbackErr.toString(), { status: 500 });
      }
    }
  }
};

async function getConfigsJson(hostName) {
  const configs = [];
  for (const entry of listProxy) {
    const { path, protocol, proxy } = entry;
    const [ipOnly] = proxy.split(':');
    const response = await fetch(`http://ip-api.com/json/${ipOnly}`);
    const data = await response.json();

    const pathFixed = encodeURIComponent(path);
    const uuid = generateUUIDv4(); 

    let configDetails = {
      isp: data.isp,
      countryCode: data.countryCode,
      protocol: protocol,
      path: path,
      proxyIp: ipOnly,
      proxyPort: proxy.split(':')[1]
    };

    if (protocol === "vless") {
      configDetails.vless = {
        tls: `vless://${entry.uuid}@${hostName}:443?encryption=none&security=tls&sni=${hostName}&fp=randomized&type=ws&host=${hostName}&path=${pathFixed}#${data.isp} (${data.countryCode})`,
        ntls: `vless://${entry.uuid}@${hostName}:80?path=${pathFixed}&security=none&encryption=none&host=${hostName}&fp=randomized&type=ws&sni=${hostName}#${data.isp} (${data.countryCode})`
      };
      configDetails.clash = {
        tls: `- name: ${data.isp} (${data.countryCode})
  server: ${hostName}
  port: 443
  type: vless
  uuid: ${entry.uuid}
  cipher: auto
  tls: true
  udp: true
  skip-cert-verify: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: ${path}
    headers:
      Host: ${hostName}`,
        ntls: `- name: ${data.isp} (${data.countryCode})
  server: ${hostName}
  port: 80
  type: vless
  uuid: ${entry.uuid}
  cipher: auto
  tls: false
  udp: true
  skip-cert-verify: true
  network: ws
  ws-opts:
    path: ${path}
    headers:
      Host: ${hostName}`
      };
    } else if (protocol === "vmess") {
      const vmessConfigTls = {
        v: "2", ps: `${data.isp} (${data.countryCode})`, add: hostName, port: "443",
        id: entry.uuid, aid: entry.alterId || 0, net: "ws", type: "none",
        host: hostName, path: path, tls: "tls", sni: hostName
      };
      configDetails.vmess = {
        tls: `vmess://${btoa(JSON.stringify(vmessConfigTls))}`,
        ntls: `vmess://${btoa(JSON.stringify({ ...vmessConfigTls, port: "80", tls: "" }))}`
      };
      configDetails.clash = {
        tls: `- name: ${data.isp} (${data.countryCode})
  server: ${hostName}
  port: 443
  type: vmess
  uuid: ${entry.uuid}
  cipher: auto
  tls: true
  udp: true
  skip-cert-verify: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: ${path}
    headers:
      Host: ${hostName}`,
        ntls: `- name: ${data.isp} (${data.countryCode})
  server: ${hostName}
  port: 80
  type: vmess
  uuid: ${entry.uuid}
  cipher: auto
  tls: false
  udp: true
  skip-cert-verify: true
  network: ws
  ws-opts:
    path: ${path}
    headers:
      Host: ${hostName}`
      };
    } else if (protocol === "trojan") {
      configDetails.trojan = {
        tls: `trojan://${entry.password}@${hostName}:443?sni=${hostName}&type=ws&host=${hostName}&path=${pathFixed}#${data.isp} (${data.countryCode})`,
        ntls: `trojan://${entry.password}@${hostName}:80?type=ws&host=${hostName}&path=${pathFixed}#${data.isp} (${data.countryCode})`
      };
      configDetails.clash = {
        tls: `- name: ${data.isp} (${data.countryCode})
  server: ${hostName}
  port: 443
  type: trojan
  password: ${entry.password}
  tls: true
  udp: true
  skip-cert-verify: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: ${path}
    headers:
      Host: ${hostName}`,
        ntls: `- name: ${data.isp} (${data.countryCode})
  server: ${hostName}
  port: 80
  type: trojan
  password: ${entry.password}
  tls: false
  udp: true
  skip-cert-verify: true
  network: ws
  ws-opts:
    path: ${path}
    headers:
      Host: ${hostName}`
      };
    }
    configs.push(configDetails);
  }
  return {
    wildcardDomains: [
      "ava.game.naver.com", "graph.instagram.com", "quiz.int.vidio.com",
      "live.iflix.com", "support.zoom.us", "blog.webex.com",
      "cache.netflix.com", "investors.spotify.com", "zaintest.vuclip.com"
    ],
    configurations: configs
  };
}

async function getUrlsTxt(hostName) {
  let urls = [];
  for (const entry of listProxy) {
    const { path, protocol, proxy } = entry;
    const [ipOnly] = proxy.split(':');
    const response = await fetch(`http://ip-api.com/json/${ipOnly}`);
    const data = await response.json();

    const pathFixed = encodeURIComponent(path);
    const uuid = generateUUIDv4();

    if (protocol === "vless") {
      urls.push(`vless://${entry.uuid}@${hostName}:443?encryption=none&security=tls&sni=${hostName}&fp=randomized&type=ws&host=${hostName}&path=${pathFixed}#${data.isp} (${data.countryCode})`.replace(/ /g, "+"));
      urls.push(`vless://${entry.uuid}@${hostName}:80?path=${pathFixed}&security=none&encryption=none&host=${hostName}&fp=randomized&type=ws&sni=${hostName}#${data.isp} (${data.countryCode})`.replace(/ /g, "+"));
    } else if (protocol === "vmess") {
      const vmessConfigTls = {
        v: "2", ps: `${data.isp} (${data.countryCode})`, add: hostName, port: "443",
        id: entry.uuid, aid: entry.alterId || 0, net: "ws", type: "none",
        host: hostName, path: path, tls: "tls", sni: hostName
      };
      urls.push(`vmess://${btoa(JSON.stringify(vmessConfigTls))}`);
      const vmessConfigNtls = { ...vmessConfigTls, port: "80", tls: "" };
      urls.push(`vmess://${btoa(JSON.stringify(vmessConfigNtls))}`);
    } else if (protocol === "trojan") {
      urls.push(`trojan://${entry.password}@${hostName}:443?sni=${hostName}&type=ws&host=${hostName}&path=${pathFixed}#${data.isp} (${data.countryCode})`);
      urls.push(`trojan://${entry.password}@${hostName}:80?type=ws&host=${hostName}&path=${pathFixed}#${data.isp} (${data.countryCode})`);
    }
  }
  return urls.join('\n');
}

async function vlessOverWSHandler(request, configEntry) {
  const webSocketPair = new WebSocketPair();
  const [client, webSocket] = Object.values(webSocketPair);
  webSocket.accept();

  const log = (info, event) => { console.log(`[VLESS] ${info}`, event || ""); };
  const earlyDataHeader = request.headers.get("sec-websocket-protocol") || "";

  const readableWebSocketStream = makeReadableWebSocketStream(webSocket, earlyDataHeader, log);
  let remoteSocketWapper = { value: null };
  let udpStreamWrite = null;
  let isDns = false;

  readableWebSocketStream.pipeTo(new WritableStream({
    async write(chunk, controller) {

      if (isDns && udpStreamWrite) {
        return udpStreamWrite(chunk);
      }
      if (remoteSocketWapper.value) {
        const writer = remoteSocketWapper.value.writable.getWriter();
        await writer.write(chunk);
        writer.releaseLock();
        return;
      }

      const {
        hasError, message, portRemote = 443, addressRemote = "",
        rawDataIndex, vlessVersion = new Uint8Array([0, 0]), isUDP
      } = processVlessHeader(chunk);

      if (hasError) {
        log(`VLESS header error: ${message}`);
        webSocket.close(1008, message);
        controller.error(message);
        return;
      }

      if (isUDP) {
        if (portRemote === 53) {
          isDns = true;
        } else {
          log("UDP proxy only enabled for DNS (port 53)");
          webSocket.close(1008, "UDP proxy only for DNS");
          controller.error("UDP proxy only for DNS");
          return;
        }
      }

      const vlessResponseHeader = new Uint8Array([vlessVersion[0], 0]);
      const rawClientData = chunk.slice(rawDataIndex);

      if (isDns) {
        const { write } = await handleUDPOutBound(webSocket, vlessResponseHeader, log);
        udpStreamWrite = write;
        udpStreamWrite(rawClientData);
        return;
      }

      handleTCPOutBound(remoteSocketWapper, addressRemote, portRemote, rawClientData, webSocket, vlessResponseHeader, log);
    },
    close() { log(`readableWebSocketStream is close`); },
    abort(reason) { log(`readableWebSocketStream is abort`, JSON.stringify(reason)); }
  })).catch((err) => {
    log("readableWebSocketStream pipeTo error", err);
  });

  return new Response(null, { status: 101, webSocket: client });
}

async function vmessOverWSHandler(request, configEntry) {
  const webSocketPair = new WebSocketPair();
  const [client, webSocket] = Object.values(webSocketPair);
  webSocket.accept();

  const log = (info, event) => { console.log(`[VMess] ${info}`, event || ""); };

  webSocket.addEventListener("message", async (event) => {
    const data = event.data; 
    let remoteAddress = "127.0.0.1"; 
    let remotePort = 443; 
    let isAuthenticated = false; 

    try {
      const initialData = new Uint8Array(data);
      isAuthenticated = true; 

      if (!isAuthenticated) {
        log("VMess authentication failed.");
        webSocket.close(1008, "VMess authentication failed.");
        return;
      }

      const tcpSocket = connect({ hostname: remoteAddress, port: remotePort });
      const writer = tcpSocket.writable.getWriter();
      const reader = tcpSocket.readable.getReader();

      webSocket.addEventListener("message", async (event) => {
        await writer.write(event.data);
      });

      (async () => {
        while (true) {
          const { value, done } = await reader.read();
          if (done) break;
          webSocket.send(value);
        }
      })();

    } catch (e) {
      log(`VMess connection error: ${e.message}`);
      webSocket.close(1011, `VMess connection error: ${e.message}`);
    }
  });

  webSocket.addEventListener("close", () => log("VMess WebSocket closed"));
  webSocket.addEventListener("error", (err) => log(`VMess WebSocket error: ${err.message}`));

  return new Response(null, { status: 101, webSocket: client });
}

async function trojanOverWSHandler(request, configEntry) {
  const webSocketPair = new WebSocketPair();
  const [client, webSocket] = Object.values(webSocketPair);
  webSocket.accept();

  const log = (info, event) => { console.log(`[Trojan] ${info}`, event || ""); };

  let isAuthenticated = false;
  let remoteSocketWapper = { value: null };

  webSocket.addEventListener("message", async (event) => {
    const data = event.data; 

    if (!isAuthenticated) {
      const initialData = new Uint8Array(data);
      const decoder = new TextDecoder();
      const dataString = decoder.decode(initialData);

      const parts = dataString.split('\r\n\r\n');
      if (parts.length < 2) {
        log("Incomplete Trojan handshake.");
        webSocket.close(1008, "Incomplete Trojan handshake.");
        return;
      }

      const clientPassword = parts[0];
      if (clientPassword !== configEntry.password) {
        log("Invalid Trojan password.");
        webSocket.close(1008, "Invalid Trojan password.");
        return;
      }

      isAuthenticated = true;
      log("Trojan authenticated.");

      const commandAndAddress = parts[1];
      const connectRegex = /CONNECT\s+([a-zA-Z0-9\.-]+):(\d+)/;
      const match = commandAndAddress.match(connectRegex);

      let remoteAddress = "127.0.0.1"; 
      let remotePort = 443; 
      let rawClientData = new Uint8Array(0); 

      if (match) {
        remoteAddress = match[1];
        remotePort = parseInt(match[2], 10);
        rawClientData = initialData.slice(parts[0].length + 4 + match[0].length);
      } else {
        log("Trojan command not recognized, using default proxy.");
        remoteAddress = proxyIP;
        remotePort = proxyPort;
        rawClientData = initialData.slice(parts[0].length + 4); 
      }

      try {
        const tcpSocket = connect({ hostname: remoteAddress, port: remotePort });
        remoteSocketWapper.value = tcpSocket;
        log(`Connected to Trojan remote: ${remoteAddress}:${remotePort}`);

        const writer = tcpSocket.writable.getWriter();
        if (rawClientData.length > 0) {
          await writer.write(rawClientData);
        }
        writer.releaseLock();

        remoteSocketToWS(tcpSocket, webSocket, new Uint8Array([0]), null, log); 

      } catch (e) {
        log(`Trojan remote connection error: ${e.message}`);
        webSocket.close(1011, `Trojan remote connection error: ${e.message}`);
      }

    } else {
      if (remoteSocketWapper.value) {
        const writer = remoteSocketWapper.value.writable.getWriter();
        await writer.write(data);
        writer.releaseLock();
      } else {
        log("Trojan remote socket not established.");
        webSocket.close(1011, "Trojan remote socket not established.");
      }
    }
  });

  webSocket.addEventListener("close", () => log("Trojan WebSocket closed"));
  webSocket.addEventListener("error", (err) => log(`Trojan WebSocket error: ${err.message}`));

  return new Response(null, { status: 101, webSocket: client });
}

async function handleTCPOutBound(remoteSocket, addressRemote, portRemote, rawClientData, webSocket, responseHeader, log) {
  async function connectAndWrite(address, port) {
    const tcpSocket2 = connect({ hostname: address, port });
    remoteSocket.value = tcpSocket2;
    log(`connected to ${address}:${port}`);
    const writer = tcpSocket2.writable.getWriter();
    await writer.write(rawClientData);
    writer.releaseLock();
    return tcpSocket2;
  }

  async function retry() {
    const tcpSocket2 = await connectAndWrite(proxyIP || addressRemote, proxyPort || portRemote);
    tcpSocket2.closed.catch((error) => {
      console.log("retry tcpSocket closed error", error);
    }).finally(() => {
      safeCloseWebSocket(webSocket);
    });
    remoteSocketToWS(tcpSocket2, webSocket, responseHeader, null, log);
  }

  const tcpSocket = await connectAndWrite(addressRemote, portRemote);
  remoteSocketToWS(tcpSocket, webSocket, responseHeader, retry, log);
}

function makeReadableWebSocketStream(webSocketServer, earlyDataHeader, log) {
  let readableStreamCancel = false;
  const stream = new ReadableStream({
    start(controller) {
      webSocketServer.addEventListener("message", (event) => {
        if (readableStreamCancel) return;
        controller.enqueue(event.data);
      });
      webSocketServer.addEventListener("close", () => {
        safeCloseWebSocket(webSocketServer);
        if (readableStreamCancel) return;
        controller.close();
      });
      webSocketServer.addEventListener("error", (err) => {
        log("webSocketServer has error");
        controller.error(err);
      });
      const { earlyData, error } = base64ToArrayBuffer(earlyDataHeader);
      if (error) {
        controller.error(error);
      } else if (earlyData) {
        controller.enqueue(earlyData);
      }
    },
    pull(controller) {},
    cancel(reason) {
      if (readableStreamCancel) return;
      log(`ReadableStream was canceled, due to ${reason}`);
      readableStreamCancel = true;
      safeCloseWebSocket(webSocketServer);
    }
  });
  return stream;
}

function processVlessHeader(vlessBuffer) {
  if (vlessBuffer.byteLength < 24) {
    return { hasError: true, message: "invalid data" };
  }
  const version = new Uint8Array(vlessBuffer.slice(0, 1));
  let isUDP = false;

  const optLength = new Uint8Array(vlessBuffer.slice(17, 18))[0];
  const command = new Uint8Array(vlessBuffer.slice(18 + optLength, 18 + optLength + 1))[0];

  if (command === 1) { /* TCP */ }
  else if (command === 2) { isUDP = true; }
  else {
    return { hasError: true, message: `command ${command} is not support, command 01-tcp,02-udp,03-mux` };
  }

  const portIndex = 18 + optLength + 1;
  const portBuffer = vlessBuffer.slice(portIndex, portIndex + 2);
  const portRemote = new DataView(portBuffer).getUint16(0);

  let addressIndex = portIndex + 2;
  const addressBuffer = new Uint8Array(vlessBuffer.slice(addressIndex, addressIndex + 1));
  const addressType = addressBuffer[0];

  let addressLength = 0;
  let addressValueIndex = addressIndex + 1;
  let addressValue = "";

  switch (addressType) {
    case 1: 
      addressLength = 4;
      addressValue = new Uint8Array(vlessBuffer.slice(addressValueIndex, addressValueIndex + addressLength)).join(".");
      break;
    case 2: 
      addressLength = new Uint8Array(vlessBuffer.slice(addressValueIndex, addressValueIndex + 1))[0];
      addressValueIndex += 1;
      addressValue = new TextDecoder().decode(vlessBuffer.slice(addressValueIndex, addressValueIndex + addressLength));
      break;
    case 3: 
      addressLength = 16;
      const dataView = new DataView(vlessBuffer.slice(addressValueIndex, addressValueIndex + addressLength));
      const ipv6 = [];
      for (let i = 0; i < 8; i++) {
        ipv6.push(dataView.getUint16(i * 2).toString(16));
      }
      addressValue = ipv6.join(":");
      break;
    default:
      return { hasError: true, message: `invild addressType is ${addressType}` };
  }

  if (!addressValue) {
    return { hasError: true, message: `addressValue is empty, addressType is ${addressType}` };
  }

  return {
    hasError: false,
    addressRemote: addressValue,
    addressType,
    portRemote,
    rawDataIndex: addressValueIndex + addressLength,
    vlessVersion: version,
    isUDP
  };
}

async function remoteSocketToWS(remoteSocket, webSocket, responseHeader, retry, log) {
  let hasIncomingData = false;
  await remoteSocket.readable.pipeTo(
    new WritableStream({
      start() {},
      async write(chunk, controller) {
        hasIncomingData = true;
        if (webSocket.readyState !== WS_READY_STATE_OPEN) {
          controller.error("webSocket.readyState is not open, maybe close");
        }
        if (responseHeader) {
          webSocket.send(await new Blob([responseHeader, chunk]).arrayBuffer());
          responseHeader = null; 
        } else {
          webSocket.send(chunk);
        }
      },
      close() { log(`remoteConnection!.readable is close with hasIncomingData is ${hasIncomingData}`); },
      abort(reason) { console.error(`remoteConnection!.readable abort`, reason); }
    })
  ).catch((error) => {
    console.error(`remoteSocketToWS has exception `, error.stack || error);
    safeCloseWebSocket(webSocket);
  });

  if (hasIncomingData === false && retry) {
    log(`retry`);
    retry();
  }
}

function base64ToArrayBuffer(base64Str) {
  if (!base64Str) { return { error: null }; }
  try {
    base64Str = base64Str.replace(/-/g, "+").replace(/_/g, "/");
    const decode = atob(base64Str);
    const arryBuffer = Uint8Array.from(decode, (c) => c.charCodeAt(0));
    return { earlyData: arryBuffer.buffer, error: null };
  } catch (error) {
    return { error };
  }
}

var WS_READY_STATE_OPEN = 1;
var WS_READY_STATE_CLOSING = 2;

function safeCloseWebSocket(socket) {
  try {
    if (socket.readyState === WS_READY_STATE_OPEN || socket.readyState === WS_READY_STATE_CLOSING) {
      socket.close();
    }
  } catch (error) {
    console.error("safeCloseWebSocket error", error);
  }
}

async function handleUDPOutBound(webSocket, vlessResponseHeader, log) {
  let isVlessHeaderSent = false;
  const transformStream = new TransformStream({
    start(controller) {},
    transform(chunk, controller) {
      for (let index = 0; index < chunk.byteLength; ) {
        const lengthBuffer = chunk.slice(index, index + 2);
        const udpPakcetLength = new DataView(lengthBuffer).getUint16(0);
        const udpData = new Uint8Array(chunk.slice(index + 2, index + 2 + udpPakcetLength));
        index = index + 2 + udpPakcetLength;
        controller.enqueue(udpData);
      }
    },
    flush(controller) {}
  });

  transformStream.readable.pipeTo(new WritableStream({
    async write(chunk) {
      const resp = await fetch(
        "https://1.1.1.1/dns-query",
        {
          method: "POST",
          headers: { "content-type": "application/dns-message" },
          body: chunk
        }
      );
      const dnsQueryResult = await resp.arrayBuffer();
      const udpSize = dnsQueryResult.byteLength;
      const udpSizeBuffer = new Uint8Array([udpSize >> 8 & 255, udpSize & 255]);
      if (webSocket.readyState === WS_READY_STATE_OPEN) {
        log(`doh success and dns message length is ${udpSize}`);
        if (isVlessHeaderSent) {
          webSocket.send(await new Blob([udpSizeBuffer, dnsQueryResult]).arrayBuffer());
        } else {
          webSocket.send(await new Blob([vlessResponseHeader, udpSizeBuffer, dnsQueryResult]).arrayBuffer());
          isVlessHeaderSent = true;
        }
      }
    }
  })).catch((error) => {
    log("dns udp has error" + error);
  });

  const writer = transformStream.writable.getWriter();
  return { write(chunk) { writer.write(chunk); } };
}

function generateUUIDv4() {
  const randomValues = crypto.getRandomValues(new Uint8Array(16));
  randomValues[6] = randomValues[6] & 15 | 64;
  randomValues[8] = randomValues[8] & 63 | 128;
  return [
    randomValues[0].toString(16).padStart(2, "0"),
    randomValues[1].toString(16).padStart(2, "0"),
    randomValues[2].toString(16).padStart(2, "0"),
    randomValues[3].toString(16).padStart(2, "0"),
    randomValues[4].toString(16).padStart(2, "0"),
    randomValues[5].toString(16).padStart(2, "0"),
    randomValues[6].toString(16).padStart(2, "0"),
    randomValues[7].toString(16).padStart(2, "0"),
    randomValues[8].toString(16).padStart(2, "0"),
    randomValues[9].toString(16).padStart(2, "0"),
    randomValues[10].toString(16).padStart(2, "0"),
    randomValues[11].toString(16).padStart(2, "0"),
    randomValues[12].toString(16).padStart(2, "0"),
    randomValues[13].toString(16).padStart(2, "0"),
    randomValues[14].toString(16).padStart(2, "0"),
    randomValues[15].toString(16).padStart(2, "0")
  ].join("").replace(/^(.{8})(.{4})(.{4})(.{4})(.{12})$/, "$1-$2-$3-$4-$5");
}

export { worker_default as default };
