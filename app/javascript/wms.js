// 足し算の合計が間違っていたら色を塗る
const color = () => {
  const story_a_sum_wrong = document.getElementsByClassName('story_a_sum_wrong')
  if (story_a_sum_wrong.length > 0) {
    Array.prototype.forEach.call(
      story_a_sum_wrong,
      (element) => {
        element.style.backgroundColor = "#FFC0CB";
      }
    )
  }

  const story_b_sum_wrong = document.getElementsByClassName('story_b_sum_wrong')
  if (story_b_sum_wrong.length > 0) {
    Array.prototype.forEach.call(
      story_b_sum_wrong,
      (element) => {
        element.style.backgroundColor = "#FFC0CB";
      }
    )
  }

  const wms_sum_wrong = document.getElementsByClassName('wms_sum_wrong')
  if (wms_sum_wrong.length > 0) {
    Array.prototype.forEach.call(
      wms_sum_wrong,
      (element) => {
        element.style.backgroundColor = "#FFC0CB";
      }
    )
  }
}

alert("注意：更新ボタンは押さないでください。");
color();