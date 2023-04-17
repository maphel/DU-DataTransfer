# EchoCast

EchoCast is a library specifically designed for data transmission in Dual Universe, leveraging the powerful Dual Universe API to enable seamless communication between emitter and receiver units within the game. This library serves as a critical building block for players looking to develop intricate in-game systems, automate processes, and enhance their overall gameplay experience.

Built with performance and reliability in mind, EchoCast ensures that data is transmitted efficiently and accurately, minimizing the chances of lost or corrupted information. The library is equipped with features such as error handling, queue management, and timeout control to guarantee smooth and consistent data flow between devices.

In addition to its core functionality, EchoCast is also highly adaptable and can be easily integrated with a wide range of in-game systems and devices. Its flexible architecture allows users to customize and extend the library's capabilities to suit their specific needs, making it an invaluable tool for both novice and expert players alike.

With EchoCast, Dual Universe enthusiasts can unlock the full potential of their in-game creations, establishing more complex and dynamic interactions between devices and systems. By providing a reliable and powerful solution for data transmission, EchoCast serves as a key component for fostering innovation, creativity, and collaboration within the Dual Universe community.

## Features

- Master/Slave Architecture
- Automated request/response system
- Data is stored in database for persistence

## Usage

To set up EchoCast for both Master and Slave, you will need the following components:

1. A Programming Board
2. A Databank
3. A Receiver
4. An Emitter

Both the Master and the Slave require the same set of components, but the way they are linked to the Programming Board differs. Follow the steps below to set up the components and establish the appropriate connections.

# Master Setup

1. Place a Programming Board, a Databank, a Receiver, and an Emitter in close proximity to each other.
2. Open the link creation mode.
3. Link the Programming Board to the Databank by clicking on the Programming Board first and then on the Databank.
4. Link the Programming Board to the Emitter in the same way.
5. Finally, link the Programming Board to the Receiver. For the Master, the link should be established from the Programming Board to the Receiver.

# Slave Setup

1. Place a Programming Board, a Databank, a Receiver, and an Emitter in close proximity to each other. (~max 500-800m away from Master)
2. Open the link creation mode.
3. Link the Programming Board to the Databank by clicking on the Programming Board first and then on the Databank.
4. Link the Programming Board to the Emitter in the same way.
5. Finally, link the Programming Board to the Receiver. For the Slave, the link should be established from the Receiver to the Programming Board.

By following these steps, you can ensure that the EchoCast Master and Slave components are properly set up and connected, allowing for seamless data transmission and efficient communication between devices in Dual Universe.

### Initializing

To initialize EchoCast you need to create a new instance of the EchoCast class on your Programming Boards using `unit.start()`. This can be done by doing the following.

```lua
master = EchoCastMaster:new()
slave = EchoCastSlave:new()
```

### EchoCastMaster

The `EchoCastMaster` class is used to initiate requests. It has the following functions:

#### addRequest

The `addRequest` function is used to add a request to the queue. It takes the following parameters:

- `reqChannel`: The channel to send the request on
- `resChannel`: The channel to expect the response on
- `addFirst` (optional): If `true` is passed then the request will be added to the front of the queue, otherwise it will be added to the back

#### onUpdate

The `onUpdate` function is called once per update cycle and is used to process the queue and handle timeouts.

#### onReceived

The `onReceived` function is called when a message is received on the specified channel. It takes the following parameters:

- `channel`: The channel the message was recieved on
- `message`: The message that was recieved

### EchoCastSlave

The `EchoCastSlave` class is used to respond to requests. It has the following functions:

#### addResponse

The `addResponse` function is used to add a response to the queue. It takes the following parameters:

- `resChannel`: The channel to send the response on
- `message`: The message to send

#### onUpdate

The `onUpdate` function is called once per update cycle and is used to process the queue.

## Example

# Master
```lua
-- unit.start()
function onProgressChange(dto)
    system.print("Progress changed!")
    system.print(dto.channel)
    system.print(dto.chunk)
    system.print(dto.chunkIndex)
    system.print(dto.totalChunks)
end

function onFinish(dto)
    system.print("Progress finished!")
    system.print(dto.channel)
    system.print(dto.message)
    system.print(dto.chunkIndex)
    system.print(dto.totalChunks)
end

master = EchoCastMaster:new(onFinish, onProgressChange)
master:clearDB()
master:addRequest("req1", "res1")
master:addRequest("req2", "res2")

-- system.update
master:onUpdate()

-- receiver.onReceived(*,*)
master:onReceived(channel, message)
```

# Slave
```lua
function onFinish(dto)
    system.print(dto.channel)
    system.print(dto.chunkData)
    system.print(dto.chunkIndex)
    system.print(dto.totalChunks)
end

slave = EchoCastSlave:new(onFinish)
slave:addResponse("res1", "Lorem ipsum dolor sit amet.")
slave:onUpdate()
unit.exit()
```