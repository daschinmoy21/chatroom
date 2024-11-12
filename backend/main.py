from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import List
import json
from sqlalchemy import create_engine, Column, Integer, String, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from databases import Database

app = FastAPI()

DATABASE_URL = "sqlite:///./chat.db"
database = Database(DATABASE_URL)
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
Base = declarative_base()

class Server(Base):
    __tablename__ = "servers"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    icon = Column(String)  # Store icon letter or URL
    channels = relationship("Channel", back_populates="server")

class Channel(Base):
    __tablename__ = "channels"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    server_id = Column(Integer, ForeignKey("servers.id"))
    server = relationship("Server", back_populates="channels")
    messages = relationship("Message", back_populates="channel")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(String, index=True)
    message = Column(Text)
    type = Column(String)
    channel_id = Column(Integer, ForeignKey("channels.id"))
    channel = relationship("Channel", back_populates="messages")

Base.metadata.create_all(bind=engine)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Initialize some servers and channels
def init_servers():
    session = SessionLocal()
    if session.query(Server).count() == 0:
        # Create Gaming server
        gaming_server = Server(name="Gaming Hub", icon="G")
        session.add(gaming_server)
        session.flush()
        
        # Add channels to Gaming server
        channels = [
            Channel(name="general", server_id=gaming_server.id),
            Channel(name="valorant", server_id=gaming_server.id),
            Channel(name="minecraft", server_id=gaming_server.id)
        ]
        session.add_all(channels)

        # Create Coding server
        coding_server = Server(name="Coding Zone", icon="C")
        session.add(coding_server)
        session.flush()
        
        # Add channels to Coding server
        channels = [
            Channel(name="general", server_id=coding_server.id),
            Channel(name="python", server_id=coding_server.id),
            Channel(name="flutter", server_id=coding_server.id)
        ]
        session.add_all(channels)
        
        session.commit()
    session.close()

# Connection manager for WebSocket
class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, channel_id: str):
        await websocket.accept()
        if channel_id not in self.active_connections:
            self.active_connections[channel_id] = []
        self.active_connections[channel_id].append(websocket)

    def disconnect(self, websocket: WebSocket, channel_id: str):
        if channel_id in self.active_connections:
            self.active_connections[channel_id].remove(websocket)

    async def broadcast(self, message: str, channel_id: str):
        if channel_id in self.active_connections:
            for connection in self.active_connections[channel_id]:
                await connection.send_text(message)

manager = ConnectionManager()

@app.on_event("startup")
async def startup():
    await database.connect()
    init_servers()

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

@app.get("/servers")
async def get_servers():
    session = SessionLocal()
    servers = session.query(Server).all()
    result = [{"id": s.id, "name": s.name, "icon": s.icon} for s in servers]
    session.close()
    return result

@app.get("/channels/{server_id}")
async def get_channels(server_id: int):
    session = SessionLocal()
    channels = session.query(Channel).filter(Channel.server_id == server_id).all()
    result = [{"id": c.id, "name": c.name} for c in channels]
    session.close()
    return result

@app.websocket("/ws/{channel_id}/{client_id}")
async def websocket_endpoint(websocket: WebSocket, channel_id: str, client_id: str):
    await manager.connect(websocket, channel_id)
    session = SessionLocal()
    try:
        # Send previous messages from this channel
        messages = session.query(Message).filter(Message.channel_id == channel_id).all()
        for msg in messages:
            await websocket.send_text(json.dumps({
                "client_id": msg.client_id,
                "message": msg.message,
                "type": msg.type
            }))
        
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            message["client_id"] = client_id

            # Save message to the database
            db_message = Message(
                client_id=client_id,
                message=message["message"],
                type=message["type"],
                channel_id=channel_id
            )
            session.add(db_message)
            session.commit()

            await manager.broadcast(json.dumps(message), channel_id)
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel_id)
        await manager.broadcast(json.dumps({
            "client_id": client_id,
            "message": "left the chat",
            "type": "system"
        }), channel_id)
    except Exception as e:
        print(f"Error: {e}")
    finally:
        session.close()