if(!self.define){let e,i={};const n=(n,s)=>(n=new URL(n+".js",s).href,i[n]||new Promise((i=>{if("document"in self){const e=document.createElement("script");e.src=n,e.onload=i,document.head.appendChild(e)}else e=n,importScripts(n),i()})).then((()=>{let e=i[n];if(!e)throw new Error(`Module ${n} didn’t register its module`);return e})));self.define=(s,r)=>{const d=e||("document"in self?document.currentScript.src:"")||location.href;if(i[d])return;let o={};const t=e=>n(e,d),c={module:{uri:d},exports:o,require:t};i[d]=Promise.all(s.map((e=>c[e]||t(e)))).then((e=>(r(...e),o)))}}define(["./workbox-958fa2bd"],(function(e){"use strict";self.addEventListener("message",(e=>{e.data&&"SKIP_WAITING"===e.data.type&&self.skipWaiting()})),e.precacheAndRoute([{url:"assets/index.78e34086.css",revision:null},{url:"assets/index.9a4d7ab2.js",revision:null},{url:"index.html",revision:"8705906751a607cf94a1f129d2b61a70"},{url:"registerSW.js",revision:"9fb750ec3dadfbb3d70877868ce420ad"},{url:"icon.svg",revision:"e9bb8663aa6b06cad91c3727655b6560"},{url:"favicon.ico",revision:"71613d6a22062dfb503b0c0492dd57da"},{url:"robots.txt",revision:"5e0bd1c281a62a380d7a948085bfe2d1"},{url:"apple-touch-icon.png",revision:"fd2bd681613337f7e5a8ad868308721d"},{url:"icon-192.png",revision:"125bedb8ec7865de34770b4590e397b2"},{url:"icon-512.png",revision:"80b870696cd8dde61f61068dfc3e2ffe"},{url:"manifest.webmanifest",revision:"31654afd5e481edeffa8075f9db22456"}],{}),e.cleanupOutdatedCaches(),e.registerRoute(new e.NavigationRoute(e.createHandlerBoundToURL("index.html")))}));
