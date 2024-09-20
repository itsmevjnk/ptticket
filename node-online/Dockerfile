FROM node:22-alpine

RUN mkdir -p /home/node/dbapi/node_modules && chown -R node:node /home/node/dbapi

WORKDIR /home/node/dbapi

USER node
COPY --chown=node:node . ./
RUN npm install --omit=dev

EXPOSE 3000
CMD ["npm", "start"]