# Dockerfile básico para API Node.js

# Usar imagen base de Node.js
FROM node:24

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json primero (para cache de layers)
COPY package.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto del código
COPY . .

# Exponer puerto
EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["npm", "start"] 