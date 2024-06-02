var result = document.getElementsByClassName('result');

// 不一致のレコードに色を塗る
function color (){
  for (let i = 0; i < result.length; i++) {
    let result_text = result[i].innerText;
    if (result_text === '一致しません') {
      result[i].style.backgroundColor = "#FFC0CB";
    }
  }
}

color();