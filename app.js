const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
    <h1>🐳 Docker 학습 애플리케이션 ggg</h1>
    <p>안녕하세요! Docker 컨테이너에서 실행 중입니다.</p>
    <p>현재 시간: ${new Date().toLocaleString('ko-KR')}</p>
  `);
});

app.listen(PORT, () => {
  console.log(`서버가 포트 ${PORT}에서 실행 중입니다.`);
});