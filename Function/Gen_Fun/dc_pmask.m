function dc_pmask(mainfig)

ButtonH=uicontrol('Parent', mainfig,'Style','pushbutton','String','p Mask','Position',[10 10 100 25],'Visible','on','Callback',@pmask);
%ButtonH.UserData = @ones;

    function pmask(PushButton, EventData)
        
        Axes = PushButton.Parent.Children.findobj('Type','Axes');
        Axes = Axes(arrayfun(@(c) ~isempty(c.String), [Axes.Title]));
        
        for a = 1:length(Axes)
            
            imag = Axes(a).Children.findobj('Type','Image');
            
            if isempty(imag)
                imag =  Axes(a).Children.findobj('Type','Surface');
                
            end
            
            if ~isempty(imag)
                if isempty(imag.UserData)
                    imag.UserData = logical(~isnan(imag.CData));
                end
                
                if length(size(imag.AlphaData)) < length(size(imag.UserData))
                    
                end
                
                placeholder = imag.UserData;
                imag.UserData = imag.AlphaData;
                imag.AlphaData = placeholder;
            else
                
                imag =  Axes(a).Children.findobj('Type','contour');
                

                if isempty(PushButton.UserData) 
                    PushButton.UserData = 2;
                end
                
                if PushButton.UserData > size(imag.UserData,3)
                    PushButton.UserData = 1;
                end
                
                
                %placeholder = imag.UserData;
                imag.ZData = imag.UserData(:,:,PushButton.UserData);
                %imag.ZData = placeholder;
                
                
                if PushButton.UserData ~= 1
                PushButton.String =  ['p mask ' num2str(PushButton.UserData-1)];
                else
                PushButton.String =  ['p mask off'];
                end

               
                
            end
        end
        
       PushButton.UserData = PushButton.UserData + 1;
    end
end