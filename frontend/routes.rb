ArchivesSpace::Application.routes.draw do

  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|

    scope prefix do
      match('/plugins/barcoder' => 'barcoder#index', :via => [:get])
      match('/plugins/barcoder/create' => 'barcoder#create', :via => [:post])
    end
  end
end
