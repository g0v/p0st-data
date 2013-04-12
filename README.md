# data/ 資料來源

網址來源為郵局網頁「下載專區」： <http://www.post.gov.tw/post/internet/down/index.html>

以下各檔解壓、轉碼後，直接存在 `data/` 目錄中。

- [4.4 »3+2碼郵遞區號文字檔 102/02](http://download.post.gov.tw/post/download/Zip32_10202.txt)

    curl -O http://download.post.gov.tw/post/download/Zip32_10202.txt

- [6.2 »縣市鄉鎮中英對照Excel檔(漢語拼音,csv檔)](http://download.post.gov.tw/post/download/county_h.csv)

    curl http://download.post.gov.tw/post/download/county_h.csv | piconv -f big5 -t utf8 > country_h.csv

- [6.4 »村里文字巷中英對照文字檔 101/02(漢語拼音,zip檔)](http://download.post.gov.tw/post/download/Village_H_10102.zip)

    curl -O http://download.post.gov.tw/post/download/Village_H_10102.zip
    unzip Village_H_10102.zip
    piconv -f big5 -t utf8 Village_H_10102.TXT > Village_H_10102_u.TXT
    mv -f Village_H_10102_u.TXT Village_H_10102.TXT
    rm Village_H_10102.zip

- [6.6 »路街中英對照文字檔 102/02(漢語拼音,zip檔)](http://download.post.gov.tw/post/download/CE_Rd_St_H_10202.zip)

    curl -O http://download.post.gov.tw/post/download/CE_Rd_St_H_10202.zip
    unzip CE_Rd_St_H_10202.zip
    piconv -f big5 -t utf8 CE_Rd_St_H_10202.TXT > CE_Rd_St_H_10202_u.TXT
    mv -f CE_Rd_St_H_10202_u.TXT CE_Rd_St_H_10202.TXT
    rm CE_Rd_St_H_10202.zip

- [全國營業據點](http://download.post.gov.tw/post/download/Post_All_1020328.txt)

    curl http://download.post.gov.tw/post/download/Post_All_1020328.txt | piconv -f big5 -t utf8 | perl -ple 's/(\x{d})+//' > Post_All_1020328.txt

- [全國郵局ATM分佈](http://download.post.gov.tw/post/download/post_atm_location.csv)

    curl http://download.post.gov.tw/post/download/post_atm_location.csv | piconv -f big5 -t utf8 > post_atm_location.csv
