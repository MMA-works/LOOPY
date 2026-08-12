from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "output" / "pdf" / "looply-project-handoff.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)

navy = colors.HexColor("#111B21")
yellow = colors.HexColor("#FFD54F")
amber = colors.HexColor("#D97706")
muted = colors.HexColor("#667781")
cream = colors.HexColor("#FFF9C4")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="CoverTitle", parent=styles["Title"], fontSize=30, leading=36, textColor=navy, alignment=TA_CENTER, spaceAfter=14))
styles.add(ParagraphStyle(name="CoverSub", parent=styles["Normal"], fontSize=13, leading=19, textColor=muted, alignment=TA_CENTER))
styles.add(ParagraphStyle(name="H1x", parent=styles["Heading1"], fontSize=19, leading=24, textColor=navy, spaceBefore=8, spaceAfter=10))
styles.add(ParagraphStyle(name="H2x", parent=styles["Heading2"], fontSize=13, leading=17, textColor=amber, spaceBefore=8, spaceAfter=5))
styles.add(ParagraphStyle(name="Bodyx", parent=styles["BodyText"], fontSize=10.2, leading=15, textColor=navy, spaceAfter=7))
styles.add(ParagraphStyle(name="Smallx", parent=styles["BodyText"], fontSize=8.7, leading=12, textColor=muted))

def p(text, style="Bodyx"):
    return Paragraph(text, styles[style])

def bullets(items):
    return [p("- " + item) for item in items]

def footer(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(yellow)
    canvas.rect(0, A4[1]-13, A4[0], 13, fill=1, stroke=0)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(muted)
    canvas.drawString(42, 24, "Looply Project Handoff - Safe project context (not internal Codex memory)")
    canvas.drawRightString(A4[0]-42, 24, f"Page {doc.page}")
    canvas.restoreState()

doc = SimpleDocTemplate(str(OUT), pagesize=A4, rightMargin=42, leftMargin=42, topMargin=42, bottomMargin=38, title="Looply Project Handoff")
story = [Spacer(1, 105), p("LOOPLY", "CoverTitle"), p("Project Handoff and Current Status", "CoverSub"), Spacer(1, 18)]
summary = Table([[p("Flutter", "Smallx"), p("Spring Boot", "Smallx"), p("PostgreSQL", "Smallx"), p("WebSocket", "Smallx")]], colWidths=[125]*4)
summary.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,-1),cream),("BOX",(0,0),(-1,-1),1,yellow),("INNERGRID",(0,0),(-1,-1),.5,yellow),("ALIGN",(0,0),(-1,-1),"CENTER"),("VALIGN",(0,0),(-1,-1),"MIDDLE"),("TOPPADDING",(0,0),(-1,-1),10),("BOTTOMPADDING",(0,0),(-1,-1),10)]))
story += [summary, Spacer(1, 30), p("Prepared as a safe, shareable replacement for the internal MEMORY.md request. No passwords, tokens, private keys, database credentials, or hidden system instructions are included.", "CoverSub"), PageBreak()]

story += [p("1. Product Goal", "H1x"), p("Looply is a WhatsApp-inspired but independently branded Flutter mobile chat application. The MVP lets two authenticated users exchange persistent one-to-one text, voice, and image messages in real time."),
          p("Completed MVP capabilities", "H2x")]
story += bullets(["Username/password registration and login with hashed passwords.", "Available-user directory and one-to-one conversations.", "Real-time text delivery using authenticated Spring WebSocket/STOMP.", "Voice recording, preview, upload, playback, duration and waveform UI.", "Camera/gallery image messages with authenticated retrieval and full-screen preview.", "Sent, delivered and read status, timestamps, pagination and persisted history.", "Yellow multi-shade Flutter interface with search, transitions, four-tab navigation and settings screen."])

story += [p("2. Technology Stack", "H1x")]
data = [[p("Layer","Smallx"),p("Current choice","Smallx")],
        [p("Frontend"),p("Flutter for Android and Web")],[p("Backend"),p("Java 21, Spring Boot, Maven")],
        [p("Database"),p("PostgreSQL with JPA/Hibernate and Flyway migrations")],[p("Realtime"),p("WebSocket/STOMP with JWT authentication")],
        [p("Media - local"),p("Backend local filesystem for development")],[p("Production target"),p("Railway backend, Supabase PostgreSQL and Supabase Storage")]]
t=Table(data,colWidths=[145,355],repeatRows=1)
t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),yellow),("TEXTCOLOR",(0,0),(-1,0),navy),("GRID",(0,0),(-1,-1),.5,colors.HexColor('#D9D9D9')),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),9),("RIGHTPADDING",(0,0),(-1,-1),9),("TOPPADDING",(0,0),(-1,-1),7),("BOTTOMPADDING",(0,0),(-1,-1),7)]))
story += [t, Spacer(1,8)]

story += [p("3. Workspace and Repository", "H1x")]
story += bullets(["Workspace: C:/Users/M. Ali/Desktop/WORKPLACE/PRODUCTS/Thisapp", "Folders: backend/ and mobile/.", "GitHub destination discussed: MMA-works/LOOPY.", "Git attribution is based on the commit email matching a verified email on an individual GitHub account; an organization itself is not a commit author.", "Do not commit .env files, passwords, JWT secrets, build output, APKs, local database files, or uploaded media."])

story += [p("4. Verification Evidence", "H1x")]
story += bullets(["Flutter analyzer passed with no issues after the yellow UI update.", "Flutter tests passed: 7/7.", "Spring Boot verification previously passed: 16/16 tests.", "Flutter Web and Android debug APK builds completed successfully.", "Connected Motorola device accepted an updated APK install through ADB."])

story += [PageBreak(), p("5. Current Production Setup Progress", "H1x")]
story += bullets(["Supabase project has been created.", "Data API and automatic table exposure were intentionally disabled because Spring Boot connects directly to PostgreSQL.", "Supabase Shared Pooler session connection details were identified for an IPv4 persistent backend.", "A database password was accidentally exposed in chat; it must be considered compromised and reset before production use.", "Railway service was linked to the GitHub repository and configured with backend as the root directory.", "Railway initially became online, then entered a crash loop after database configuration. The actual first 'Caused by:' error line is still required for exact diagnosis."])

story += [p("6. Immediate Next Actions", "H1x")]
next_data=[[p("Order","Smallx"),p("Action","Smallx"),p("Done when","Smallx")],
 [p("1"),p("Reset the exposed Supabase database password."),p("New password stored privately; never pasted into chat or Git.")],
 [p("2"),p("Set Railway DB_URL, DB_USERNAME, DB_PASSWORD and a new 32+ character JWT_SECRET."),p("Variables saved without exposing their values.")],
 [p("3"),p("Inspect Railway Deploy Logs from the first 'Caused by:' line."),p("Database/Flyway startup root cause is known.")],
 [p("4"),p("Redeploy and verify Flyway creates schema versions V1 and V2 in Supabase."),p("Backend remains healthy and tables exist.")],
 [p("5"),p("Generate a Railway public domain and test authenticated REST plus WebSocket."),p("Two users can chat across different internet networks.")],
 [p("6"),p("Replace local voice/image storage with private Supabase Storage."),p("Media survives backend restart/redeploy.")],
 [p("7"),p("Build a signed release APK using the public backend URL."),p("Release APK installs and completes end-to-end testing.")],
 [p("8"),p("Create a public Looply download website."),p("Users can download the signed APK and view installation/privacy information.")]]
t=Table(next_data,colWidths=[38,285,177],repeatRows=1)
t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),yellow),("GRID",(0,0),(-1,-1),.5,colors.HexColor('#D9D9D9')),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),7),("RIGHTPADDING",(0,0),(-1,-1),7),("TOPPADDING",(0,0),(-1,-1),6),("BOTTOMPADDING",(0,0),(-1,-1),6)]))
story += [t]

story += [p("7. Later Phase: Voice and Video Calls", "H1x"), p("Calls are not implemented yet. A proper production phase requires WebRTC media, authenticated WebSocket signaling, incoming call accept/reject, mute, camera controls, end-call handling, permissions, and a TURN service. STUN alone is not reliable across all carrier, NAT and corporate networks.")]

story += [p("8. Safety Rules for Continuation", "H1x")]
story += bullets(["Work one approved phase at a time and preserve existing architecture.", "Make focused changes only; do not refactor or redesign unrelated areas.", "Never hard-code or commit secrets.", "Run git status and diff inspection before commits.", "Run staged secret scanning before every push.", "Do not rewrite history or force-push without explicit approval.", "Do not claim deployment success from a green dashboard alone; verify API, WebSocket, database persistence, media and two-user behavior."])

doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
