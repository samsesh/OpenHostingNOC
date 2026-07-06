import os
import uuid
import time
import hashlib
import json
import ldap
import ldap.filter
from flask import Flask, request, Response, redirect, render_template, make_response

app = Flask(__name__)
app.secret_key = os.environ.get("AUTH_SECRET_KEY", uuid.uuid4().hex)

LDAP_HOST = os.environ.get("LDAP_HOST", "openldap")
LDAP_PORT = os.environ.get("LDAP_PORT", "389")
LDAP_BASE_DN = os.environ.get("LDAP_BASE_DN", "dc=noc,dc=example,dc=com")
LDAP_BIND_DN = os.environ.get("LDAP_BIND_DN", "cn=admin,dc=noc,dc=example,dc=com")
LDAP_BIND_PASSWORD = os.environ.get("LDAP_BIND_PASSWORD", "changeme")
LDAP_SEARCH_FILTER = os.environ.get("LDAP_SEARCH_FILTER", "(uid=%s)")
LDAP_TLS = os.environ.get("LDAP_TLS", "false").lower() == "true"
SESSION_MAX_AGE = int(os.environ.get("AUTH_SESSION_MAX_AGE", "86400"))
AUTH_DOMAIN = os.environ.get("AUTH_DOMAIN", ".example.com")

sessions = {}


def get_ldap_conn():
    uri = f"ldap://{LDAP_HOST}:{LDAP_PORT}"
    conn = ldap.initialize(uri)
    if LDAP_TLS:
        conn.start_tls_s()
    conn.set_option(ldap.OPT_PROTOCOL_VERSION, 3)
    return conn


def authenticate(username, password):
    conn = get_ldap_conn()
    try:
        conn.simple_bind_s(LDAP_BIND_DN, LDAP_BIND_PASSWORD)
        search_filter = ldap.filter.filter_format(LDAP_SEARCH_FILTER, [username])
        result = conn.search_s(
            LDAP_BASE_DN, ldap.SCOPE_SUBTREE, search_filter,
            ["dn", "mail", "cn", "uid", "memberOf"]
        )
        if not result:
            return None
        user_dn, attrs = result[0]
        conn.simple_bind_s(user_dn, password)
        mail = attrs.get("mail", [b""])[0].decode() if attrs.get("mail") else ""
        cn = attrs.get("cn", [b""])[0].decode() if attrs.get("cn") else ""
        uid = attrs.get("uid", [b""])[0].decode() if attrs.get("uid") else ""
        member_of = [g.decode() for g in attrs.get("memberOf", [])] if attrs.get("memberOf") else []
        return {"dn": user_dn, "mail": mail, "name": cn, "uid": uid, "groups": member_of}
    except ldap.INVALID_CREDENTIALS:
        return None
    finally:
        conn.unbind_s()


def generate_session(user):
    session_id = uuid.uuid4().hex
    sessions[session_id] = {
        "user": user,
        "expires": time.time() + SESSION_MAX_AGE
    }
    return session_id


def validate_session(session_id):
    data = sessions.get(session_id)
    if not data:
        return None
    if time.time() > data["expires"]:
        del sessions[session_id]
        return None
    return data["user"]


def build_forward_response(user, status=200):
    resp = Response(status=status)
    if user:
        resp.headers["X-Forwarded-User"] = user.get("uid", "")
        resp.headers["X-Forwarded-Email"] = user.get("mail", "")
        resp.headers["X-Forwarded-Groups"] = ",".join(user.get("groups", []))
        resp.headers["X-Forwarded-Name"] = user.get("name", "")
    return resp


@app.route("/auth", methods=["GET", "HEAD"])
def forward_auth():
    session_id = request.cookies.get("auth_session")
    if not session_id:
        rd = request.args.get("rd", "") or request.headers.get("X-Forwarded-Uri", "/")
        return redirect(f"/login?rd={rd}", 307)
    user = validate_session(session_id)
    if not user:
        rd = request.args.get("rd", "") or request.headers.get("X-Forwarded-Uri", "/")
        return redirect(f"/login?rd={rd}", 307)
    return build_forward_response(user)


@app.route("/login", methods=["GET"])
def login_page():
    rd = request.args.get("rd", "/")
    error = request.args.get("error", "")
    return render_template("login.html", rd=rd, error=error)


@app.route("/login", methods=["POST"])
def login_post():
    username = request.form.get("username", "")
    password = request.form.get("password", "")
    rd = request.form.get("rd", "/")
    if not username or not password:
        return redirect(f"/login?rd={rd}&error=empty")
    user = authenticate(username, password)
    if not user:
        return redirect(f"/login?rd={rd}&error=invalid")
    session_id = generate_session(user)
    resp = redirect(rd)
    resp.set_cookie(
        "auth_session", session_id,
        max_age=SESSION_MAX_AGE,
        httponly=True,
        secure=True,
        samesite="Lax",
        domain=AUTH_DOMAIN
    )
    return resp


@app.route("/logout", methods=["GET"])
def logout():
    session_id = request.cookies.get("auth_session")
    if session_id and session_id in sessions:
        del sessions[session_id]
    resp = redirect("/login")
    resp.set_cookie("auth_session", "", max_age=0, httponly=True, secure=True, samesite="Lax", domain=AUTH_DOMAIN)
    return resp


@app.route("/health", methods=["GET"])
def health():
    try:
        conn = get_ldap_conn()
        conn.simple_bind_s(LDAP_BIND_DN, LDAP_BIND_PASSWORD)
        conn.unbind_s()
        return Response("ok", status=200)
    except Exception:
        return Response("unhealthy", status=503)


@app.route("/ping", methods=["GET"])
def ping():
    return Response("pong", status=200)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
