#!/usr/bin/env python3
"""
PSP H.264 Annex-B Proxy Server
Convertit les streams Jellyfin MP4/fMP4 en H.264 Annex-B pur pour PSP
"""

import os
import sys
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
import logging

# Version du proxy
VERSION = "1.3.1"  # Fix flags2 syntax: use -weightp 0 instead

# Configuration
PROXY_PORT = int(os.environ.get('PROXY_PORT', 9000))
JELLYFIN_HOST = os.environ.get('JELLYFIN_HOST', 'localhost')
JELLYFIN_PORT = os.environ.get('JELLYFIN_PORT', '21409')
API_KEY = os.environ.get('API_KEY', '8645890e48eb48a99a9eb28a72d30362')
LOG_FILE = os.environ.get('LOG_FILE', '/app/psp-h264-proxy.log')

# Configuration logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)

class ProxyHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Override pour utiliser notre logger"""
        logging.info("%s - %s" % (self.address_string(), format % args))
    
    def do_GET(self):
        """Gérer les requêtes GET /stream/<video_id>"""
        
        # Extraire l'ID vidéo depuis le path
        if not self.path.startswith('/stream/'):
            self.send_error(400, "Format requis: /stream/<video_id>")
            return
        
        video_id = self.path[8:].split('?')[0].split('/')[0]
        
        if not video_id or len(video_id) != 32:
            self.send_error(400, "ID vidéo invalide")
            return
        
        logging.info(f"Stream demandé: {video_id}")
        
        # Construire l'URL Jellyfin (Direct Stream)
        jellyfin_url = f"http://{JELLYFIN_HOST}:{JELLYFIN_PORT}/Videos/{video_id}/stream"
        params = f"Static=true&MediaSourceId={video_id}&api_key={API_KEY}"
        
        full_url = f"{jellyfin_url}?{params}"
        
        # Headers HTTP
        self.send_response(200)
        self.send_header('Content-Type', 'video/h264')
        self.send_header('Connection', 'close')
        self.send_header('Cache-Control', 'no-cache')
        self.end_headers()
        
        # Lancer FFmpeg et streamer la sortie
        # RÉENCODAGE avec IDR forcées pour compatibilité PSP Media Engine
        # Le Media Engine DOIT commencer par une IDR (type 5)
        try:
            ffmpeg_cmd = [
                'ffmpeg',
                '-loglevel', 'error',
                '-i', full_url,
                '-map', '0:v:0',
                        # Réencodage H.264 Baseline STRICT pour PSP
                        '-c:v', 'libx264',
                        '-preset', 'ultrafast',      # Rapide (faible CPU)
                        '-tune', 'zerolatency',      # Streaming temps réel
                        '-profile:v', 'baseline',    # PSP compatible
                        '-level', '3.0',             # PSP max
                        '-pix_fmt', 'yuv420p',       # Format couleur PSP
                        '-s', '480x272',             # Résolution PSP
                        '-r', '24',                  # Framerate fixe
                        '-b:v', '512k',              # Bitrate
                        '-maxrate', '512k',
                        '-bufsize', '1M',
                        # IDR forcées
                        '-force_key_frames', 'expr:gte(n,n_forced*12)',  # IDR toutes les 12 frames
                        '-g', '12',                  # GOP size max
                        '-sc_threshold', '0',        # Désactiver scene cut detection
                        # Contraintes STRICTES Baseline (PSP Media Engine)
                        '-bf', '0',                  # PAS de B-frames
                        '-refs', '1',                # 1 seule ref frame
                        '-coder', '0',               # CAVLC (pas CABAC)
                        '-partitions', 'none',       # Désactiver partitions avancées
                        '-weightp', '0',             # Désactiver weighted prediction
                # Output
                '-f', 'h264',
                '-an',                       # Pas d'audio (simplifie)
                '-'
            ]
            
            logging.info(f"Démarrage FFmpeg pour {video_id}")
            
            # Lancer FFmpeg et pipe la sortie vers le client
            process = subprocess.Popen(
                ffmpeg_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Streamer les données par chunks
            chunk_size = 8192
            bytes_sent = 0
            
            while True:
                chunk = process.stdout.read(chunk_size)
                if not chunk:
                    break
                
                try:
                    self.wfile.write(chunk)
                    bytes_sent += len(chunk)
                except BrokenPipeError:
                    logging.warning(f"Client déconnecté après {bytes_sent} bytes")
                    process.terminate()
                    break
            
            # Attendre que FFmpeg se termine
            process.wait(timeout=5)
            
            if process.returncode != 0:
                stderr = process.stderr.read().decode('utf-8', errors='ignore')
                logging.error(f"FFmpeg error: {stderr}")
            else:
                logging.info(f"Stream terminé: {video_id} ({bytes_sent} bytes envoyés)")
                
        except Exception as e:
            logging.error(f"Erreur lors du streaming de {video_id}: {e}")
            try:
                process.terminate()
            except:
                pass

if __name__ == '__main__':
    print("=" * 50)
    print(f"PSP H.264 Annex-B Proxy v{VERSION}")
    print("=" * 50)
    print(f"Port d'écoute: {PROXY_PORT}")
    print(f"Jellyfin: {JELLYFIN_HOST}:{JELLYFIN_PORT}")
    print(f"Log: {LOG_FILE}")
    print("Mode: Direct Stream (Static=true)")
    print("Prêt à recevoir des connexions PSP...")
    print("")
    
    try:
        server = HTTPServer(('0.0.0.0', PROXY_PORT), ProxyHandler)
        logging.info(f"Serveur HTTP démarré sur le port {PROXY_PORT}")
        server.serve_forever()
    except KeyboardInterrupt:
        logging.info("Arrêt du serveur...")
        server.shutdown()
    except Exception as e:
        logging.error(f"Erreur fatale: {e}")
        sys.exit(1)

