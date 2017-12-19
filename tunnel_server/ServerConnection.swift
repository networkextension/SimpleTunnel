/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ServerConnection class. The ServerConnection class encapsulates and decapsulates a stream of network data in the server side of the SimpleTunnel tunneling protocol.
*/

import Foundation

/// An object representing the server side of a logical flow of TCP network data in the SimpleTunnel tunneling protocol.
class ServerConnection: Connection, StreamDelegate {

	// MARK: Properties

	/// The stream used to read network data from the connection.
	var readStream: InputStream?

	/// The stream used to write network data to the connection.
	var writeStream: OutputStream?

	// MARK: Interface

	/// Open the connection to a host and port.
	func open(host: String, port: Int) -> Bool {
		simpleTunnelLog("Connection \(identifier) connecting to \(host):\(port)")
		
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &readStream, outputStream: &writeStream)

        guard let newReadStream = readStream, let newWriteStream = writeStream else {
			return false
		}

		for stream in [newReadStream, newWriteStream] {
			stream.delegate = self
			stream.open()
            stream.schedule(in: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
		}

		return true
	}

	// MARK: Connection

	/// Close the connection.
    override func closeConnection(_ direction: TunnelConnectionCloseDirection) {
		super.closeConnection(direction)
		
        if let stream = writeStream, isClosedForWrite && savedData.isEmpty {
			if let error = stream.streamError {
				simpleTunnelLog("Connection \(identifier) write stream error: \(error)")
			}

            stream.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
			stream.close()
			stream.delegate = nil
			writeStream = nil
		}

        if let stream = readStream, isClosedForRead {
			if let error = stream.streamError {
				simpleTunnelLog("Connection \(identifier) read stream error: \(error)")
			}

            stream.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
			stream.close()
			stream.delegate = nil
			readStream = nil
		}
	}

	/// Abort the connection.
    override func abort(_ error: Int = 0) {
		super.abort(error)
        closeConnection(.all)
	}

	/// Stop reading from the connection.
	override func suspend() {
		if let stream = readStream {
			stream.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
		}
	}

	/// Start reading from the connection.
	override func resume() {
		if let stream = readStream {
			
            stream.schedule(in: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
		}
	}

	/// Send data over the connection.
    override func sendData(_ data: Data) {
		guard let stream = writeStream else { return }
		var written = 0

		if savedData.isEmpty {
			written = writeData(data, toStream: stream, startingAtOffset: 0)

            if written < data.count {
				// We could not write all of the data to the connection. Tell the client to stop reading data for this connection.
				
				stream.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
                tunnel?.sendSuspendForConnection(identifier)
			}
		}

        if written < data.count {
			savedData.append(data, offset: written)
		}
	}

	// MARK: NSStreamDelegate

	/// Handle an event on a stream.
	func stream(aStream:Stream, handleEvent eventCode: Stream.Event) {
		switch aStream {

			case writeStream!:
				switch eventCode {
                case [.hasSpaceAvailable]:
						if !savedData.isEmpty {
							guard savedData.writeToStream(writeStream!) else {
								tunnel?.sendCloseType(.all, forConnection: identifier)
								abort()
								break
							}

							if savedData.isEmpty {
								
                                writeStream?.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
								if isClosedForWrite {
									closeConnection(.write)
								}
								else {
									tunnel?.sendResumeForConnection(identifier)
								}
							}
						}
						else {
							writeStream?.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
						}

					case [.endEncountered]:
						tunnel?.sendCloseType(.read, forConnection: identifier)
						closeConnection(.write)

					case [.errorOccurred]:
						tunnel?.sendCloseType(.all, forConnection: identifier)
						abort()

					default:
						break
				}

			case readStream!:
				switch eventCode {
					case [.hasBytesAvailable]:
						if let stream = readStream {
							while stream.hasBytesAvailable {
                                var readBuffer = [UInt8](repeating: 0, count: 8192)
								let bytesRead = stream.read(&readBuffer, maxLength: readBuffer.count)

								if bytesRead < 0 {
									abort()
									break
								}

								if bytesRead == 0 {
									simpleTunnelLog("\(identifier): got EOF, sending close")
									tunnel?.sendCloseType(.write, forConnection: identifier)
									closeConnection(.read)
									break
								}

								let readData = NSData(bytes: readBuffer, length: bytesRead)
                                tunnel?.sendData(readData as Data, forConnection: identifier)
							}
						}

					case [.endEncountered]:
						tunnel?.sendCloseType(.write, forConnection: identifier)
						closeConnection(.read)

					case [.errorOccurred]:
						if let serverTunnel = tunnel as? ServerTunnel {
                            serverTunnel.sendOpenResultForConnection(connectionIdentifier: identifier, resultCode: .timeout)
							serverTunnel.sendCloseType(.all, forConnection: identifier)
							abort()
						}

					case [.openCompleted]:
						if let serverTunnel = tunnel as? ServerTunnel {
                            serverTunnel.sendOpenResultForConnection(connectionIdentifier: identifier, resultCode: .success)
						}

					default:
						break
				}
			default:
				break
		}
	}
}
