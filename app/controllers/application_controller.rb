class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  
  $days_of_the_week = %w{日 月 火 水 木 金 土}
  
  # beforeフィルター
  
  # paramsハッシュからユーザーを取得
  def set_user
    @user = User.find(params[:id])
  end
  
  # ログイン済みのユーザーか確認
  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = 'ログインしてください'
      redirect_to login_url
    end
  end
  
  # アクセスしたユーザーが現在ログインしているユーザーか確認
  def correct_user
    redirect_to(root_url) unless current_user?(@user)
  end
  
  # システム管理権限所有者かどうか判定
  def admin_user
    redirect_to root_url unless current_user.admin?
  end

  # ページ出力前に1か月分のデータの存在を確認しセットする
  def set_one_month
    @first_day = params[:date].nil? ?
    Date.current.beginning_of_month : params[:date].to_date
    @last_day = @first_day.end_of_month
    one_month = [*@first_day..@last_day] #対象月の日付を代入
    # ユーザーに紐づく1か月のレコードを検索して取得
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    
    unless one_month.count == @attendances.count # それぞれの件数（日数）が一致するか評価
      ActiveRecord::Base.transaction do # トランザクション開始
        # 繰り返し処理により、1か月分の勤怠データを生成
        one_month.each { |day| @user.attendances.create!(worked_on: day) }
      end
      @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end
    
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐
    flash[:danger] = "ページの情報の取得に失敗しました。再度アクセスしてください"
    redirect_to root_url
  end
end
