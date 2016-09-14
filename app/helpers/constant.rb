#encoding: utf-8
module Constant
  include RoleConstant
  LOCAL_DIR = "#{Rails.root}/public/"
 
  


  #上传图片的比例,如需更改请追加，部分已按index引用
  SALE_PICSIZE =[300,230,663,50,"sale_pics"]
  P_PICSIZE = [50,154,246,300,356,800]
  C_PICSIZE = [148,154,50,800,"pcard_pics"]
  STAFF_PICSIZE = [100]
  SVCARD_PICSIZE = [148,154,50,800]
  MICRO_STORE = [150,230]

  #角色
  SYS_ADMIN = "100001"  #系统管理员
  BOSS = "100002" #老板
  MANAGER = "100003" #店长
  STAFF = "100004" #员工

  #活动code码生成文件路径
  CODE_PATH =  LOCAL_DIR + "code_file.txt"
  LOG_DIR = LOCAL_DIR + "logs/"

  PER_PAGE = 20
  MORE_PAGE = 30
  LITE_PAGE = 10

  #施工时间（分钟）
  STATION_MIN = 30
  W_MIN = 10 #休息时间
  #催货提醒
  URGE_GOODS_CONTENT = "门店订货提醒，请关注下"


  #  施工现场文件目录
  VIDEO_DIR ="work_videos"

  #发短信url
  MESSAGE_URL = "http://mt.yeion.com"
  USERNAME = "XCRJ"
  PASSWORD = "123456"
  
  SERVER_PATH = "http://192.168.0.250:3001/"
  HEAD_OFFICE_API_PATH = "http://192.168.0.250:3002/"
  #  SERVER_PATH = "http://lantan.icar99.com/"
  #  HEAD_OFFICE_API_PATH = "http://manage.icar99.com/"

  #   SERVER_PATH = "http://bam.gankao.co"
  #  #  SERVER_PATH = "http://192.168.1.100:3001"
  #  HEAD_OFFICE_API_PATH = "http://116.255.135.175:3005/"
  #  #  HEAD_OFFICE_API_PATH = "http://192.168.1.100:3002/"

  HEAD_OFFICE = HEAD_OFFICE_API_PATH + "syncs/upload_file"
  HEAD_OFFICE_REQUEST_ZIP = HEAD_OFFICE_API_PATH + "syncs/is_generate_zip"
  HEAR_OFFICE_IPHOST= HEAD_OFFICE_API_PATH

  SVCARD_PICS = "svcardimg"
  STORE_PICS = "storeimg"
  STORE_PICSIZE = [1000,50]
  #产品和活动的类别  图片名称分别为 product_pics 和service_pics
  PRODUCT = "PRODUCT"
  SERVICE = "SERVICE"
  UNNEED_UPDATE = ['sync','item','model','jv_sync']  #不更新的表
  UNDELETE_UPDATE = ["category","role_model_relation","role","staff","store_chains_relation","department","role_menu_relation"]  #不删除的表
  DATE_START =  "2013-01"

  PIC_SIZE =1024  #按kb计算
  DATE_YEAR = 1990
  
  #消费金额区间段
  CONSUME_P = {"0-1000"=>"o.price>=0 and o.price <=1000","1000-5000"=>"o.price>1000 and o.price <=5000",
    "5000-10000"=>"o.price > 5000 and o.price <=10000","10000以上"=>"o.price > 10000"}
  PRE_DAY = 15
  ##    上面修改部分 在此处添加

  #工作订单
  WORK_ORDER_PATH = LOCAL_DIR + "work_order_data/"

  #支付宝
  PAGE_WAY = "https://www.alipay.com/cooperate/gateway.do"
  NOTIFY_URL = "http://notify.alipay.com/trade/notify_query.do"
  PARTNER_KEY = "3goqmgklinxngzq0j9ge7bxxh0jwrd0f"
  PARTNER = "2088801819580851"
  SELLER_EMAIL = "539807006@qq.com"
  CALLBACK_URL="http://localhost:3001/messages/alipay_compete"
  NONSYNCH_URL="http://localhost:3001/user/alipays/over_pay"

  MSG_PRICE = 0.06
  OWE_PRICE = -3
  OWE_WARN = {:NONE =>0,:DONE => 1}

  #系统中性别
  SEX = {:FEMALE => 0,:MALE => 1}
  SEX_NAME = {0 => "女",1=>"男"}
end