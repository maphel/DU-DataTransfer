# EchoCast

EchoCast is a comprehensive and advanced library specifically designed for data transmission in Dual Universe, leveraging the powerful Dual Universe API to enable seamless communication between emitter and receiver units within the game. This library serves as a critical building block for players looking to develop intricate in-game systems, automate processes, and enhance their overall gameplay experience.

Built with performance and reliability in mind, EchoCast ensures that data is transmitted efficiently and accurately, minimizing the chances of lost or corrupted information. The library is equipped with features such as error handling, queue management, and timeout control to guarantee smooth and consistent data flow between devices.

In addition to its core functionality, EchoCast is also highly adaptable and can be easily integrated with a wide range of in-game systems and devices. Its flexible architecture allows users to customize and extend the library's capabilities to suit their specific needs, making it an invaluable tool for both novice and expert players alike.

With EchoCast, Dual Universe enthusiasts can unlock the full potential of their in-game creations, establishing more complex and dynamic interactions between devices and systems. By providing a reliable and powerful solution for data transmission, EchoCast serves as a key component for fostering innovation, creativity, and collaboration within the Dual Universe community.

## Features

- Master/Slave Architecture
- Automated request/response system
- Data is stored in database for persistence

## Usage

### Initializing

To initialize EchoCast you need to create a new instance of the EchoCast class. This can be done by doing the following.

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
tbd