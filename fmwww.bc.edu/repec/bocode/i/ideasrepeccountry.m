%IDEAS RePEc country data and rankings
%This procedure scrapes the IDEAS/RePEc website for data on the performance
%of economists by country/state and puts that data in a spreadsheet, almost ready
%for publication on the Google Public Data Explorer
%
%This version: 7 August 2011 by Richard Tol

%%basics
month = ['01'; '02'; '03'; '04'; '05'; '06'; '07'; '08'; '09'; '10'; '11'; '12'];
nmonth = 12;
smonth = 7; %complete reporting starts in month 7, July
fmonth = 8; %complete reporting ends in month 8, August
year = ['98'; '99'; '00'; '01'; '02'; '03'; '04'; '05'; '06'; '07'; '08'; '09'; '10'; '11'];
nyear= 14;
syear= 7; %detailed reporting begins in year 7, 2004
fyear= 13; %completed reporting ends in year 13, 2010
nobs = (fyear-syear+1)*nmonth + fmonth - (nmonth-smonth+1);
address1 = 'http://ideas.repec.org/top/old/';
address2 = '/top.country.all.html';
address3 = '/top.country.';
address4 = '.html';
index = zeros(nyear,nmonth);
for j=smonth:nmonth,
    index(syear,j)=j-(smonth-1);
end
for i=syear+1:fyear,
     for j=1:nmonth,
         index(i,j)=(nmonth-smonth+1) + (i-syear-1)*nmonth + j;
     end
end
for j=1:fmonth,
     index(nyear,j)=(nmonth-smonth+1) + (nyear-syear-1)*nmonth + j;
end

regions %script to define regions
indicators %script to define indicator names

%%read data
%+4 because need to skip <TD>
shift = 4;
shift0 = 4;
tfihs = 1; 
%6 because that's the sequence before the next <TD>
tfihs0 = 6;
%first year
y=syear;
for m= smonth:nmonth,
    processrank  %script to process rank data by month
    processscore %script to process score data by month
end
for y = syear+1:fyear,
    for m= 1:nmonth,
        %formatting changed in Nov 2007
        if (y == 10) & (m == 11),
            %+19 because need to skip <TD><FONT SIZE=-1>
           shift = 18;
           %-8 because that's the sequence </FONT> + 1 before </TD>
           tfihs = 8;
       end
       processrank
       processscore
    end
end
%final year
y=nyear;
for m= 1:fmonth,
    processrank
    processscore
end

%%reorganize
date = str2double(strcat('20',year(syear,1),year(syear,2),'.',month(smonth,1),month(smonth,2)));
for m=smonth+1:nmonth,
    date = [date; str2double(strcat('20',year(syear,1),year(syear,2),'.',month(m,1),month(m,2)))];
end
for y=syear+1:fyear,
    for m=1:nmonth,
        date = [date; str2double(strcat('20',year(y,1),year(y,2),'.',month(m,1),month(m,2)))];
    end
end
for m=1:fmonth,
    date = [date; str2double(strcat('20',year(nyear,1),year(nyear,2),'.',month(m,1),month(m,2)))];
end
date = repmat(date,ncountries,1);
for i=1:nindic,
    reportrank(:,i)=reshape(rank(:,:,i),nobs*ncountries,1);
    reportscore(:,i)=reshape(score(:,:,i),nobs*ncountries,1);
end

%%write
xlswrite('c:\users\rtol\desktop\webscrape\country.xlsx',date,'rank','C2');
xlswrite('c:\users\rtol\desktop\webscrape\country.xlsx',reportrank,'rank','D2');
xlswrite('c:\users\rtol\desktop\webscrape\country.xlsx',date,'score','C2');
xlswrite('c:\users\rtol\desktop\webscrape\country.xlsx',reportscore,'score','D2');