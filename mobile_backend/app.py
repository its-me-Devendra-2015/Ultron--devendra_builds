import os
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from livekit import api
from pydantic import BaseModel, Field

app = FastAPI(title="ULTRON Mobile Session API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ULTRON_ALLOWED_ORIGINS", "").split(",") if os.getenv("ULTRON_ALLOWED_ORIGINS") else [],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)
bearer = HTTPBearer(auto_error=False)


class SessionRequest(BaseModel):
    mode: str = Field(pattern="^(companion|independent)$")


async def require_device(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> str:
    expected = os.getenv("ULTRON_MOBILE_BEARER_TOKEN", "")
    if not expected:
        raise HTTPException(503, "Mobile device authentication is not configured.")
    if credentials is None or not secrets.compare_digest(credentials.credentials, expected):
        raise HTTPException(401, "Invalid or missing ULTRON device token.")
    return "paired-mobile-device"


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/api/mobile/session")
async def create_mobile_session(
    request: SessionRequest,
    device_id: str = Depends(require_device),
):
    livekit_url = os.getenv("LIVEKIT_URL", "")
    api_key = os.getenv("LIVEKIT_API_KEY", "")
    api_secret = os.getenv("LIVEKIT_API_SECRET", "")
    agent_name = os.getenv("ULTRON_AGENT_NAME", "my-agent")
    if not all((livekit_url, api_key, api_secret)):
        raise HTTPException(503, "LiveKit server configuration is incomplete.")

    if request.mode == "companion" and not os.getenv("ULTRON_COMPANION_ENABLED", "0") == "1":
        raise HTTPException(503, "Companion mode is not enabled until the authenticated desktop bridge is online.")

    room_name = f"ultron-{request.mode}-{secrets.token_urlsafe(12)}"
    identity = f"mobile-{secrets.token_hex(6)}"
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)

    try:
        participant_token = (
            api.AccessToken(api_key, api_secret)
            .with_identity(identity)
            .with_name("ULTRON Mobile")
            .with_ttl(timedelta(minutes=10))
            .with_grants(
                api.VideoGrants(
                    room_join=True,
                    room=room_name,
                    can_publish=True,
                    can_subscribe=True,
                    can_publish_data=True,
                )
            )
            .to_jwt()
        )

        async with api.LiveKitAPI(
            url=livekit_url,
            api_key=api_key,
            api_secret=api_secret,
        ) as lkapi:
            await lkapi.agent_dispatch.create_dispatch(
                api.CreateAgentDispatchRequest(
                    agent_name=agent_name,
                    room=room_name,
                    metadata='{"source":"ultron-mobile","mode":"' + request.mode + '","device":"' + device_id + '"}',
                )
            )
    except Exception as exc:
        raise HTTPException(502, f"Could not create ULTRON LiveKit session: {exc}") from exc

    return {
        "server_url": livekit_url,
        "room_name": room_name,
        "participant_token": participant_token,
        "expires_at": expires_at.isoformat(),
    }
